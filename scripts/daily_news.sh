#!/bin/bash
set -uo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_ROOT}"
REPO_DIR="$(cd "$REPO_DIR" && pwd -P)"
PROMPT_FILE="${PROMPT_FILE:-$SCRIPT_ROOT/scripts/daily_news_prompt.txt}"
CODEX_PROMPT_FILE="${CODEX_PROMPT_FILE:-$SCRIPT_ROOT/scripts/daily_news_prompt.codex.txt}"
CLAUDE_BIN="${CLAUDE_BIN:-/opt/homebrew/bin/claude}"
# launchdは.zshrcを読まずPATHが/usr/bin等に限られるため、python3を明示的に解決する。
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || true)}"
if [ ! -x "$PYTHON_BIN" ]; then
  for candidate in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    [ -x "$candidate" ] && PYTHON_BIN="$candidate" && break
  done
fi
LINE_MSG_FILE="$REPO_DIR/everyday_news/line_message.txt"
DAILY_SOURCE_FILE="$REPO_DIR/logs/daily_news_source.txt"
DAILY_NEWS_SOURCE="codex"
if [ -f "$DAILY_SOURCE_FILE" ]; then
  IFS=$'\t' read -r SAVED_SOURCE_DATE SAVED_SOURCE_AGENT _ < "$DAILY_SOURCE_FILE" || true
  if [ "${SAVED_SOURCE_DATE:-}" = "$(date +%Y-%m-%d)" ] \
     && [ "${SAVED_SOURCE_AGENT:-}" = "claude" ]; then
    DAILY_NEWS_SOURCE="claude"
  fi
fi

cd "$REPO_DIR"
AI_NEWS_DATE="$(date +%Y-%m-%d)"
AI_NEWS_MIN_ITEMS=5
export AI_NEWS_DATE

source "$SCRIPT_ROOT/scripts/lib/codex_fallback.sh"
source "$SCRIPT_ROOT/scripts/lib/daily_news_output.sh"
source "$SCRIPT_ROOT/scripts/lib/line_notification_dedupe.sh"
source "$SCRIPT_ROOT/scripts/lib/news_update_lock.sh"

if ! acquire_news_update_lock "$REPO_DIR"; then
  LOCK_ERROR="別の日次・週次ニュース更新が実行中のため、今回の更新を中止しました"
  echo "$LOCK_ERROR" >&2
  LOCK_ERROR_TARGET="$(line_notification_error_claim_target "$LINE_MSG_FILE" "$LOCK_ERROR")"
  if claim_line_notification "$LOCK_ERROR_TARGET" >/dev/null 2>&1; then
    if ! send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$(line_notification_failure_text "$LOCK_ERROR" 1)"; then
      echo "更新ロック競合のLINE通知に失敗しました" >&2
      release_line_notification_claim "$LOCK_ERROR_TARGET" || true
    fi
  fi
  exit 1
fi
trap 'release_news_update_lock "$REPO_DIR"' EXIT

# 日次処理中のWrite/Editフックは本文を送らず、commit・pushとSUMMARY確認後に送る。
export LINE_NOTIFY_DEFER=1
IS_FALLBACK=0
OUTPUT=""
STATUS=1

AGENT_BASE_DIR="${AI_NEWS_AGENT_WORKSPACE:-${TMPDIR:-/private/tmp}/ai-news-agent-workspace}"
AGENT_REPO_DIR=""
DAILY_OUTPUTS=(
  "everyday_news/${AI_NEWS_DATE:0:4}${AI_NEWS_DATE:5:2}.md"
  everyday_news/line_message.txt
  docs/glossary.md
  history/daily-data.js
  history/glossary-data.js
)

snapshot_daily_targets() {
  local path target
  git -C "$REPO_DIR" rev-parse HEAD || return 1
  for path in "${DAILY_OUTPUTS[@]}"; do
    target="$REPO_DIR/$path"
    if [ -L "$target" ] || [ -L "$(dirname "$target")" ]; then
      echo "更新対象にシンボリックリンクがあります: $path" >&2
      return 1
    fi
    printf '%s\n' "$path"
    git -C "$REPO_DIR" ls-files --stage -- "$path" || return 1
    if [ -f "$target" ]; then
      git -C "$REPO_DIR" hash-object -- "$target" || return 1
    elif [ -e "$target" ]; then
      echo "更新対象が通常ファイルではありません: $path" >&2
      return 1
    else
      printf '%s\n' '(absent)'
    fi
  done
}

daily_targets_have_staged_changes() {
  ! git -C "$REPO_DIR" diff --cached --quiet -- "${DAILY_OUTPUTS[@]}"
}

daily_targets_have_unstaged_changes() {
  local path
  if ! git -C "$REPO_DIR" diff --quiet -- "${DAILY_OUTPUTS[@]}"; then
    return 0
  fi
  # line_message.txt is intentionally ignored and is not part of the commit.
  for path in "${DAILY_OUTPUTS[@]}"; do
    [ "$path" = everyday_news/line_message.txt ] && continue
    if [ -e "$REPO_DIR/$path" ] \
       && ! git -C "$REPO_DIR" ls-files --error-unmatch -- "$path" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

agent_output_is_complete() {
  local final_line="${1##*$'\n'}"
  [[ "$final_line" == 'SUMMARY: OK:'* ]] \
    && ! has_output_line_prefix "$1" 'SUMMARY: ERROR:'
}

prepare_agent_workspace() {
  local path source target base
  local -a required_files=(
    docs/glossary.md
    history/daily-data.js
    history/glossary-data.js
    scripts/generate_daily_data.py
    scripts/generate_glossary_data.py
    scripts/validate_daily_news.py
    scripts/agent-bin/git
  )
  [ ! -L "$AGENT_BASE_DIR" ] || return 1
  mkdir -p "$AGENT_BASE_DIR" || return 1
  base="$(cd "$AGENT_BASE_DIR" && pwd -P)" || return 1
  case "$base/" in
    "$REPO_DIR/"*) echo "AI作業用コピーを本体repo内に作成できません" >&2; return 1 ;;
  esac
  AGENT_REPO_DIR="$(mktemp -d "$base/run.XXXXXX")" || return 1
  mkdir -p "$AGENT_REPO_DIR/everyday_news" "$AGENT_REPO_DIR/docs" \
    "$AGENT_REPO_DIR/history" "$AGENT_REPO_DIR/scripts/agent-bin" || return 1
  if [ -n "$(find "$AGENT_REPO_DIR" -name .git -print -quit)" ]; then
    echo "AI作業用コピー内に.gitが存在します。安全のため更新を中止します: $AGENT_REPO_DIR" >&2
    return 1
  fi
  for path in "${required_files[@]}"; do
    source="$REPO_DIR/$path"
    target="$AGENT_REPO_DIR/$path"
    [ -f "$source" ] || continue
    [ ! -L "$source" ] || return 1
    mkdir -p "$(dirname "$target")" || return 1
    cp -p "$source" "$target" || return 1
  done
  while IFS= read -r -d '' path; do
    case "$path" in
      *.md)
        [ ! -L "$REPO_DIR/$path" ] || return 1
        mkdir -p "$AGENT_REPO_DIR/$(dirname "$path")" || return 1
        cp -p "$REPO_DIR/$path" "$AGENT_REPO_DIR/$path" || return 1
        ;;
    esac
  done < <(git -C "$REPO_DIR" ls-files --cached --others --exclude-standard -z -- everyday_news)
  if [ -f "$LINE_MSG_FILE" ]; then
    [ ! -L "$LINE_MSG_FILE" ] || return 1
    cp -p "$LINE_MSG_FILE" "$AGENT_REPO_DIR/everyday_news/line_message.txt" || return 1
  fi
  # 前回の失敗で作業ツリーに残った用語集の変更を再通知できるよう、HEAD版も渡す。
  if [ -f "$REPO_DIR/docs/glossary.md" ]; then
    [ ! -L "$REPO_DIR/docs/glossary.md" ] || return 1
    if ! git -C "$REPO_DIR" show HEAD:docs/glossary.md > "$AGENT_REPO_DIR/docs/glossary.base.md"; then
      echo "HEAD版の用語集をAI作業用コピーへ用意できませんでした" >&2
      return 1
    fi
  else
    mkdir -p "$AGENT_REPO_DIR/docs" || return 1
    : > "$AGENT_REPO_DIR/docs/glossary.base.md" || return 1
  fi
  return 0
}

sync_agent_outputs() {
  local path source target current_state
  if daily_targets_have_staged_changes; then
    echo "同期直前に更新対象のstaged変更を検出したため、本体への同期を中止します" >&2
    return 1
  fi
  current_state="$(snapshot_daily_targets)" || return 1
  if [ "$current_state" != "$DAILY_TARGET_STATE" ]; then
    echo "実行開始後に更新対象の作業ツリーまたはindexが変化したため、本体への同期を中止します" >&2
    return 1
  fi
  if [ -n "$(find "$AGENT_REPO_DIR" -type l -print -quit)" ]; then
    echo "AI作業用コピーにシンボリックリンクがあるため、本体への同期を中止します" >&2
    return 1
  fi
  for path in "${DAILY_OUTPUTS[@]}"; do
    source="$AGENT_REPO_DIR/$path"
    target="$REPO_DIR/$path"
    [ -f "$source" ] || continue
    [ ! -L "$source" ] && [ ! -L "$target" ] || return 1
    mkdir -p "$(dirname "$target")" || return 1
    cp -p "$source" "$target" || return 1
  done
}

if daily_targets_have_staged_changes; then
  OUTPUT="SUMMARY: ERROR: 日次ニュースの更新対象に既存のstaged変更があるため、AI作業を開始しません"
  STATUS=1
elif daily_targets_have_unstaged_changes; then
  OUTPUT="SUMMARY: ERROR: 日次ニュースの更新対象に既存のunstaged変更があるため、AI作業を開始しません"
  STATUS=1
elif ! DAILY_TARGET_STATE="$(snapshot_daily_targets)"; then
  OUTPUT="SUMMARY: ERROR: 更新対象の開始時状態を記録できませんでした"
  STATUS=1
elif ! prepare_agent_workspace; then
  OUTPUT="SUMMARY: ERROR: AI作業用コピーを安全に準備できませんでした"
  STATUS=1
else
  echo "Codexで日次ニュース更新を開始します"
  OUTPUT="$(REPO_DIR="$AGENT_REPO_DIR" run_codex "$AGENT_REPO_DIR" "$CODEX_PROMPT_FILE" "$REPO_DIR" 2>&1)"
  STATUS=$?
  echo "$OUTPUT"

  if [ "$STATUS" -ne 0 ] || is_codex_limit_reached "$OUTPUT"; then
    if is_codex_limit_reached "$OUTPUT"; then
      echo "Codexの利用上限を示すメッセージを検出したため、Claude Code経由でフォールバック実行します"
    else
      echo "Codexでの更新に失敗したため、Claude Code経由でフォールバック実行します"
    fi
    IS_FALLBACK=1
    # Codexが途中まで編集した内容をClaudeの成功成果物へ混ぜない。
    if ! prepare_agent_workspace; then
      OUTPUT="SUMMARY: ERROR: フォールバック用の新しい作業用コピーを準備できませんでした"
      STATUS=1
    else
      OUTPUT="$(REPO_DIR="$AGENT_REPO_DIR" run_claude_fallback "$AGENT_REPO_DIR" "$PROMPT_FILE" "$CLAUDE_BIN" 2>&1)"
      STATUS=$?
      echo "$OUTPUT"
    fi
  fi
  if [ -n "$(find "$AGENT_REPO_DIR" -type l -print -quit)" ]; then
    OUTPUT+=$'\nSUMMARY: ERROR: AI作業用コピーにシンボリックリンクがあります'
    STATUS=1
  elif [ "$STATUS" -eq 0 ] && agent_output_is_complete "$OUTPUT"; then
    if ! AI_NEWS_GENERATION_ROOT="$AGENT_REPO_DIR" "$PYTHON_BIN" "$SCRIPT_ROOT/scripts/generate_daily_data.py" \
       || ! AI_NEWS_GENERATION_ROOT="$AGENT_REPO_DIR" "$PYTHON_BIN" "$SCRIPT_ROOT/scripts/generate_glossary_data.py" \
       || ! "$PYTHON_BIN" "$SCRIPT_ROOT/scripts/validate_daily_news.py" \
            --repo "$AGENT_REPO_DIR" --date "$AI_NEWS_DATE" --min-items "$AI_NEWS_MIN_ITEMS"; then
      OUTPUT+=$'\nSUMMARY: ERROR: 作業用コピーの生成または最低5件の検査に失敗しました'
      STATUS=1
    fi
  fi
  if [ "$STATUS" -eq 0 ] && agent_output_is_complete "$OUTPUT"; then
    if ! sync_agent_outputs; then
      OUTPUT+=$'\nSUMMARY: ERROR: AI作業用コピーから成果物を戻せませんでした'
      STATUS=1
    fi
  fi
fi

if [ "$STATUS" -eq 0 ] && has_output_line_prefix "$OUTPUT" 'SUMMARY: ERROR:'; then
  STATUS=1
fi
if [ "$STATUS" -eq 0 ] && ! agent_output_is_complete "$OUTPUT"; then
  echo "最終行に成功を示すSUMMARY: OK:がないため、日次更新を失敗扱いにします" >&2
  STATUS=1
fi

SUMMARY_KIND="$(echo "$OUTPUT" | grep '^SUMMARY:' | tail -1 | sed 's/^SUMMARY: *//')"
SUMMARY="${SUMMARY_KIND:-SUMMARY行がありません}"
if [[ "$SUMMARY_KIND" == ERROR:* ]]; then
  ERROR_REASON="${SUMMARY_KIND#ERROR:}"
  ERROR_REASON="${ERROR_REASON#"${ERROR_REASON%%[![:space:]]*}"}"
  [ -n "$ERROR_REASON" ] || ERROR_REASON="エラー原因が空です"
else
  ERROR_REASON="$(line_notification_error_detail "$OUTPUT")"
  if [ -z "$ERROR_REASON" ]; then
    if has_output_line_prefix "$OUTPUT" 'SUMMARY: OK:'; then
      ERROR_REASON="SUMMARY: OK: は出力されましたが、コマンドが終了コード ${STATUS} で終了しました"
    else
      ERROR_REASON="SUMMARY: ERROR: がないまま終了コード ${STATUS} で終了しました"
    fi
  fi
fi
SUMMARY="${SUMMARY#OK: }"
SUMMARY="${SUMMARY#ERROR: }"

commit_and_push_daily_news() {
  local news_file="everyday_news/${AI_NEWS_DATE:0:4}${AI_NEWS_DATE:5:2}.md"
  local current_branch target
  local -a targets=()
  current_branch="$(git -C "$REPO_DIR" branch --show-current)"
  if [ "$current_branch" != "main" ]; then
    echo "AIニュースの日次commit・push先はmainですが、現在のブランチは${current_branch:-detached HEAD}です" >&2
    return 1
  fi

  for target in "$news_file" history/daily-data.js docs/glossary.md history/glossary-data.js; do
    if [ -e "$REPO_DIR/$target" ] || git -C "$REPO_DIR" ls-files --error-unmatch "$target" >/dev/null 2>&1; then
      targets+=("$target")
    fi
  done

  if ! git -C "$REPO_DIR" diff --cached --quiet -- "${targets[@]}"; then
    echo "日次ニュースの更新対象に既存のstaged変更があるため、上書きを避けて処理を中止します" >&2
    return 1
  fi
  if ! git -C "$REPO_DIR" add -- "${targets[@]}"; then
    git -C "$REPO_DIR" reset -q HEAD -- "${targets[@]}" || true
    echo "日次ニュース更新対象をGitインデックスへ登録できませんでした" >&2
    return 1
  fi

  if ! git -C "$REPO_DIR" diff --cached --quiet -- "${targets[@]}"; then
    if ! git_with_daily_news_hooks -C "$REPO_DIR" commit --only \
      -m "$AI_NEWS_DATE のAIニュースを更新" -- "${targets[@]}"; then
      git -C "$REPO_DIR" reset -q HEAD -- "${targets[@]}" || true
      echo "日次ニュースのcommitに失敗しました" >&2
      return 1
    fi
  fi

  if ! "$PYTHON_BIN" "$SCRIPT_ROOT/scripts/validate_daily_news.py" \
    --repo "$REPO_DIR" --date "$AI_NEWS_DATE" --min-items "$AI_NEWS_MIN_ITEMS" --revision HEAD; then
    echo "commit済みの日次ニュース件数が最低5件に届きません" >&2
    return 1
  fi
  if ! git_with_daily_news_hooks -C "$REPO_DIR" push origin main; then
    echo "日次ニュースのpushに失敗しました" >&2
    return 1
  fi
}

# 5件検査フックの設定と実行時情報は、親プロセスが所有するcommit/pushだけへ渡す。
git_with_daily_news_hooks() {
  local config_index="${GIT_CONFIG_COUNT:-0}"
  local -a git_env=(
    "GIT_CONFIG_COUNT=$((config_index + 1))"
    "GIT_CONFIG_KEY_${config_index}=core.hooksPath"
    "GIT_CONFIG_VALUE_${config_index}=$SCRIPT_ROOT/scripts/git-hooks"
    "AI_NEWS_MIN_ITEMS=$AI_NEWS_MIN_ITEMS"
    "AI_NEWS_DATE=$AI_NEWS_DATE"
    "AI_NEWS_VALIDATOR=$SCRIPT_ROOT/scripts/validate_daily_news.py"
    "AI_NEWS_PYTHON_BIN=$PYTHON_BIN"
  )
  env "${git_env[@]}" git "$@"
}
# macOS通知を出す。本文はAppleScriptのソースに埋め込まず、引数(argv)として渡す。
#
# 以前は本文を文字列リテラルに直接埋め込み、`cut -c1-200` で長さを詰めていたが、
# launchdはロケールを渡さないためCロケールになり、`cut -c` が文字ではなくバイトを
# 数える。日本語は1文字3バイトなので200バイト目が文字の途中に当たると壊れたUTF-8が
# できあがり、osascriptが「unknown tokenが見つかりました」で落ちて朝の通知が出なかった
# (logs/daily_news.err.log に32回記録)。
# argv渡しなら引用符・バックスラッシュのエスケープが不要になり、切り詰めもAppleScript
# 側の `text 1 thru` が文字単位で行うのでロケールに左右されない。
notify() {  # $1=本文 $2=タイトル $3=サウンド名
  osascript -e 'on run argv
	set body to item 1 of argv
	if (count of body) > 200 then set body to (text 1 thru 200 of body) & "…"
	display notification body with title (item 2 of argv) sound name (item 3 of argv)
end run' "$1" "$2" "$3" || true
}

mark_as_claude_fallback() {
  printf '⚠️Claude Code経由\n%s' "$1"
}

if [ "$STATUS" -eq 0 ] && ! "$PYTHON_BIN" "$SCRIPT_ROOT/scripts/validate_daily_news.py" \
  --repo "$REPO_DIR" --date "$AI_NEWS_DATE" --min-items "$AI_NEWS_MIN_ITEMS"; then
  STATUS=1
  ERROR_REASON="当日分ニュースが最低5件に届かないため、成功通知を中止しました"
fi
if [ "$STATUS" -eq 0 ]; then
  DAILY_NEWS_SOURCE="codex"
  [ "$IS_FALLBACK" -eq 0 ] || DAILY_NEWS_SOURCE="claude"
fi
if [ "$STATUS" -eq 0 ] && ! commit_and_push_daily_news; then
  STATUS=1
  ERROR_REASON="日次ニュースの件数検査後のcommit・pushに失敗しました"
fi
if [ "$STATUS" -eq 0 ] \
   && { ! mkdir -p "$(dirname "$DAILY_SOURCE_FILE")" \
     || ! printf '%s\t%s\n' "$AI_NEWS_DATE" "$DAILY_NEWS_SOURCE" > "$DAILY_SOURCE_FILE"; }; then
  STATUS=1
  ERROR_REASON="LINE通知の経由情報を保存できませんでした"
fi

AUDIO_DATE="$(date +%Y-%m-%d)"
AUDIO_SOURCE_FILE="everyday_news/${AUDIO_DATE:0:4}${AUDIO_DATE:5:2}.md"
AUDIO_READY=0
if git rev-parse --verify HEAD >/dev/null 2>&1 \
   && git show "HEAD:$AUDIO_SOURCE_FILE" 2>/dev/null | grep "^## $AUDIO_DATE$" >/dev/null; then
  AUDIO_READY=1
fi
NEWS_SECTION_COMMITTED=0
if git show "HEAD:$AUDIO_SOURCE_FILE" 2>/dev/null \
   | grep -E "^##[[:space:]]+$AUDIO_DATE([[:space:]].*)?$" >/dev/null; then
  NEWS_SECTION_COMMITTED=1
fi

if [ "$STATUS" -eq 0 ] && [ "$NEWS_SECTION_COMMITTED" -ne 1 ]; then
  STATUS=1
  ERROR_REASON="当日分のニュース見出しがcommit済みの履歴にありません"
elif [ "$STATUS" -eq 0 ] && ! line_notification_has_current_message "$LINE_MSG_FILE"; then
  STATUS=1
  ERROR_REASON="当日の日付を含むLINE通知本文が生成されていません"
fi

if [ "$STATUS" -eq 0 ] && [ "$NEWS_SECTION_COMMITTED" -eq 1 ] && [ -s "$LINE_MSG_FILE" ] \
   && claim_line_notification "$LINE_MSG_FILE" >/dev/null 2>&1; then
    LINE_MESSAGE="$(line_notification_text "$LINE_MSG_FILE")"
    if [ "$DAILY_NEWS_SOURCE" = "claude" ]; then
      LINE_MESSAGE="$(mark_as_claude_fallback "$LINE_MESSAGE")"
    fi
    if ! send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$LINE_MESSAGE"; then
      echo "LINE通知の送信に失敗したため、次回実行で再送します" >&2
      release_line_notification_claim "$LINE_MSG_FILE" || true
    fi
fi

if [ "$STATUS" -ne 0 ]; then
  ERROR_LINE_TARGET="$(line_notification_error_claim_target "$LINE_MSG_FILE" "$ERROR_REASON")"
fi
if [ "$STATUS" -ne 0 ] && claim_line_notification "$ERROR_LINE_TARGET" >/dev/null 2>&1; then
  ERROR_LINE_MESSAGE="$(line_notification_failure_text "$ERROR_REASON" "$STATUS")"
  if ! send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$ERROR_LINE_MESSAGE"; then
    echo "LINE失敗通知の送信に失敗しました。送信APIのエラーをログで確認してください" >&2
    release_line_notification_claim "$ERROR_LINE_TARGET" || true
  fi
fi

if [ "$STATUS" -eq 0 ] || [ "$AUDIO_READY" -eq 1 ]; then
  AUDIO_SCRIPT="${NOTEBOOKLM_AUDIO_SCRIPT:-$SCRIPT_ROOT/scripts/generate_notebooklm_audio.sh}"
  AUDIO_DATA_SCRIPT="$SCRIPT_ROOT/scripts/generate_audio_data.py"
  AUDIO_DATA_FILE="$REPO_DIR/history/audio-data.js"
  AUDIO_TITLE_FILE="$REPO_DIR/history/audio-titles.json"
  AUDIO_DIR="$REPO_DIR/history/audio"
  # 音声本体（1本10〜40MB）はリポジトリを肥大化させるためGitには入れず、
  # GitHub Releasesのアセットとして配信する。Gitに入れるのはJSONとJSの目録だけ。
  AUDIO_REPO="${AUDIO_REPO:-motoki4869/ai_news}"
  AUDIO_RELEASE_TAG="${AUDIO_RELEASE_TAG:-audio}"
  AUDIO_BASE_URL="${AUDIO_BASE_URL:-https://github.com/$AUDIO_REPO/releases/download/$AUDIO_RELEASE_TAG}"
  GH_BIN="${GH_BIN:-$(command -v gh || true)}"
  [ -x "$GH_BIN" ] || GH_BIN=/opt/homebrew/bin/gh

  if [ ! -x "$AUDIO_SCRIPT" ]; then
    echo "NotebookLM音声スクリプトがないため、音声更新をスキップします: $AUDIO_SCRIPT" >&2
  elif [ ! -x "$GH_BIN" ]; then
    echo "ghコマンドが見つからないため、音声更新をスキップします: $GH_BIN" >&2
  else
    # ローカルに音声を残さない運用のため、生成済みかどうかはリリース側で判定する。
    AUDIO_DATES_FILE="$(mktemp "${TMPDIR:-/tmp}/ai-news-audio-assets.XXXXXX")"
    if "$GH_BIN" release view "$AUDIO_RELEASE_TAG" --repo "$AUDIO_REPO" \
       --json assets --jq '.assets[].name' > "$AUDIO_DATES_FILE" 2>/dev/null \
       && grep -qx "$AUDIO_DATE.m4a" "$AUDIO_DATES_FILE"; then
      echo "本日の音声は既にリリースにあるため生成をスキップします: $AUDIO_DATE"
    else
      "$AUDIO_SCRIPT" "$AUDIO_DATE" || true

      if [ -s "$AUDIO_DIR/$AUDIO_DATE.m4a" ]; then
        "$GH_BIN" release upload "$AUDIO_RELEASE_TAG" "$AUDIO_DIR/$AUDIO_DATE.m4a" \
          --repo "$AUDIO_REPO" --clobber \
          || echo "音声のリリースへのアップロードに失敗しました。ニュース更新は継続します。" >&2
      fi
    fi

    if ! "$GH_BIN" release view "$AUDIO_RELEASE_TAG" --repo "$AUDIO_REPO" \
         --json assets --jq '.assets[].name' > "$AUDIO_DATES_FILE" 2>/dev/null; then
      echo "リリースのアセット一覧を取得できませんでした。ニュース更新は継続します。" >&2
    elif ! "$PYTHON_BIN" "$AUDIO_DATA_SCRIPT" \
         --dates-file "$AUDIO_DATES_FILE" \
         --titles-file "$AUDIO_TITLE_FILE" \
         --base-url "$AUDIO_BASE_URL" \
         --output "$AUDIO_DATA_FILE"; then
      echo "NotebookLM音声一覧の生成に失敗しました。ニュース更新は継続します。" >&2
    else
      AUDIO_PATHS=("$AUDIO_DATA_FILE")
      if [ -f "$AUDIO_TITLE_FILE" ]; then
        AUDIO_PATHS+=("$AUDIO_TITLE_FILE")
      fi
      if ! git diff --quiet -- "${AUDIO_PATHS[@]}" || [ -n "$(git ls-files --others --exclude-standard -- "${AUDIO_PATHS[@]}")" ]; then
        git add "${AUDIO_PATHS[@]}"
        if git diff --cached --quiet -- "${AUDIO_PATHS[@]}"; then
          echo "NotebookLM音声の変更はありません"
        elif git_with_daily_news_hooks commit -m "$AUDIO_DATE のAIニュース音声を追加" -- "${AUDIO_PATHS[@]}"; then
          git_with_daily_news_hooks push origin main || echo "NotebookLM音声のpushに失敗しました。ニュース更新は継続します。" >&2
        else
          echo "NotebookLM音声のコミットに失敗しました。ニュース更新は継続します。" >&2
        fi
      fi
    fi
    # リリースに上がっている音声のローカルコピーは残さない。
    # 上げ損ねた分だけが手元に残り、翌日の実行でリトライ対象になる。
    if [ -d "$AUDIO_DIR" ]; then
      while IFS= read -r asset_name; do
        case "$asset_name" in
          *.m4a) rm -f "$AUDIO_DIR/$asset_name" ;;
        esac
      done < "$AUDIO_DATES_FILE"
    fi
    rm -f "$AUDIO_DATES_FILE"
  fi
fi

if [ "$STATUS" -eq 0 ]; then
  if [ "$IS_FALLBACK" -eq 1 ]; then
    notify "${SUMMARY}（Claude Code経由）" "AIニュース更新" "Glass"
  else
    notify "$SUMMARY" "AIニュース更新" "Glass"
  fi
else
  if [ "$IS_FALLBACK" -eq 1 ]; then
    notify "Codexに続きClaude Codeでの更新も失敗しました" "AIニュース更新 失敗" "Basso"
  else
    notify "daily_news.shが失敗しました: ${ERROR_REASON}。logs/daily_news.err.logを確認してください" "AIニュース更新 失敗" "Basso"
  fi
fi

exit "$STATUS"
