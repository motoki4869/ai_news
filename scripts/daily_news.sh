#!/bin/bash
set -uo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="${REPO_DIR:-$SCRIPT_ROOT}"
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

cd "$REPO_DIR"

source "$SCRIPT_ROOT/scripts/lib/codex_fallback.sh"
source "$SCRIPT_ROOT/scripts/lib/line_notification_dedupe.sh"
source "$SCRIPT_ROOT/scripts/lib/news_update_lock.sh"

if ! acquire_news_update_lock "$REPO_DIR"; then
  echo "別の日次・週次ニュース更新が実行中のため、今回の更新を中止します" >&2
  exit 1
fi
trap 'release_news_update_lock "$REPO_DIR"' EXIT

OUTPUT="$("$CLAUDE_BIN" -p "$(cat "$PROMPT_FILE")" \
  --allowedTools "Read Write Edit WebSearch Bash" 2>&1)"
STATUS=$?

echo "$OUTPUT"

IS_FALLBACK=0
if [ "$STATUS" -ne 0 ] && is_claude_limit_reached "$OUTPUT"; then
  echo "Claude利用上限に到達したため、Codex経由でフォールバック実行します"
  OUTPUT="$(run_codex_fallback "$REPO_DIR" "$CODEX_PROMPT_FILE" 2>&1)"
  STATUS=$?
  echo "$OUTPUT"
  IS_FALLBACK=1
fi

if [ "$STATUS" -eq 0 ] && printf '%s\n' "$OUTPUT" | grep -q '^SUMMARY: ERROR:'; then
  STATUS=1
fi
if [ "$STATUS" -eq 0 ] && ! printf '%s\n' "$OUTPUT" | grep -q '^SUMMARY: OK:'; then
  echo "成功を示すSUMMARY: OK:がないため、日次更新を失敗扱いにします" >&2
  STATUS=1
fi

SUMMARY_KIND="$(echo "$OUTPUT" | grep '^SUMMARY:' | tail -1 | sed 's/^SUMMARY: *//')"
SUMMARY="${SUMMARY_KIND:-SUMMARY行がありません}"
if [[ "$SUMMARY_KIND" == ERROR:* ]]; then
  ERROR_REASON="${SUMMARY_KIND#ERROR: }"
else
  ERROR_REASON="SUMMARY: ERROR: がないまま終了コード ${STATUS} で終了しました"
fi
SUMMARY="${SUMMARY#OK: }"
SUMMARY="${SUMMARY#ERROR: }"
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

AUDIO_DATE="$(date +%Y-%m-%d)"
AUDIO_SOURCE_FILE="everyday_news/${AUDIO_DATE:0:4}${AUDIO_DATE:5:2}.md"
AUDIO_READY=0
if git rev-parse --verify HEAD >/dev/null 2>&1 \
   && git show "HEAD:$AUDIO_SOURCE_FILE" 2>/dev/null | grep -q "^## $AUDIO_DATE$"; then
  AUDIO_READY=1
fi

if [ "$STATUS" -eq 0 ] && [ "$AUDIO_READY" -eq 1 ] && [ -s "$LINE_MSG_FILE" ] \
   && claim_line_notification "$LINE_MSG_FILE" >/dev/null 2>&1; then
    # ClaudeがBashで通知文を書いた場合でも、ここで短いLINE通知を送る。
    if ! send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$(line_notification_text)"; then
      echo "LINE通知の送信に失敗したため、次回実行で再送します" >&2
      release_line_notification_claim "$LINE_MSG_FILE" || true
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
        elif git commit -m "$AUDIO_DATE のAIニュース音声を追加" -- "${AUDIO_PATHS[@]}"; then
          git push origin main || echo "NotebookLM音声のpushに失敗しました。ニュース更新は継続します。" >&2
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
    notify "${SUMMARY}（Codex経由）" "AIニュース更新" "Glass"
  else
    notify "$SUMMARY" "AIニュース更新" "Glass"
  fi
else
  if [ "$IS_FALLBACK" -eq 1 ]; then
    notify "Claude利用上限到達 → Codexフォールバックも失敗しました" "AIニュース更新 失敗" "Basso"
  else
    notify "daily_news.shが失敗しました: ${ERROR_REASON}。logs/daily_news.err.logを確認してください" "AIニュース更新 失敗" "Basso"
  fi
fi

exit "$STATUS"
