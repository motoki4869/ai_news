#!/bin/bash
set -uo pipefail

REPO_DIR="/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.txt"
CODEX_PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.codex.txt"
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

source "$REPO_DIR/scripts/lib/codex_fallback.sh"

LINE_MSG_MTIME_BEFORE=0
[ -f "$LINE_MSG_FILE" ] && LINE_MSG_MTIME_BEFORE=$(stat -f %m "$LINE_MSG_FILE" 2>/dev/null || echo 0)
LINE_MSG_HASH_BEFORE=""
[ -f "$LINE_MSG_FILE" ] && LINE_MSG_HASH_BEFORE=$(md5 -q "$LINE_MSG_FILE" 2>/dev/null || echo "")

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

SUMMARY="$(echo "$OUTPUT" | grep '^SUMMARY:' | tail -1 | sed 's/^SUMMARY: *//')"
SUMMARY="${SUMMARY:-ニュースを更新しました}"
# AppleScript文字列リテラルに埋め込むため \ と " をエスケープし、通知の表示上限に合わせて短く切る
SUMMARY_ESCAPED="$(printf '%s' "$SUMMARY" | cut -c1-200 | sed 's/\\/\\\\/g; s/"/\\"/g')"

if [ "$STATUS" -eq 0 ]; then
  AUDIO_SCRIPT="${NOTEBOOKLM_AUDIO_SCRIPT:-$REPO_DIR/scripts/generate_notebooklm_audio.sh}"
  AUDIO_DATA_SCRIPT="$REPO_DIR/scripts/generate_audio_data.py"
  AUDIO_DATA_FILE="$REPO_DIR/history/audio-data.js"
  AUDIO_TITLE_FILE="$REPO_DIR/history/audio-titles.json"
  AUDIO_DIR="$REPO_DIR/history/audio"
  AUDIO_DATE="$(date +%Y-%m-%d)"
  # 音声本体（1本10〜40MB）はリポジトリを肥大化させるためGitには入れず、
  # GitHub Releasesのアセットとして配信する。Gitに入れるのはJSONとJSの目録だけ。
  AUDIO_REPO="${AUDIO_REPO:-motoki4869/ai_news}"
  AUDIO_RELEASE_TAG="${AUDIO_RELEASE_TAG:-audio}"
  AUDIO_BASE_URL="${AUDIO_BASE_URL:-https://github.com/$AUDIO_REPO/releases/download/$AUDIO_RELEASE_TAG}"
  # ローカルの音声は保持日数を過ぎたら消す。本体はリリース側に残り続ける。0で無効。
  AUDIO_LOCAL_RETENTION_DAYS="${AUDIO_LOCAL_RETENTION_DAYS:-7}"
  GH_BIN="${GH_BIN:-$(command -v gh || true)}"
  [ -x "$GH_BIN" ] || GH_BIN=/opt/homebrew/bin/gh

  if [ ! -x "$AUDIO_SCRIPT" ]; then
    echo "NotebookLM音声スクリプトがないため、音声更新をスキップします: $AUDIO_SCRIPT" >&2
  elif [ ! -x "$GH_BIN" ]; then
    echo "ghコマンドが見つからないため、音声更新をスキップします: $GH_BIN" >&2
  else
    "$AUDIO_SCRIPT" "$AUDIO_DATE" || true

    if [ -s "$AUDIO_DIR/$AUDIO_DATE.m4a" ]; then
      "$GH_BIN" release upload "$AUDIO_RELEASE_TAG" "$AUDIO_DIR/$AUDIO_DATE.m4a" \
        --repo "$AUDIO_REPO" --clobber \
        || echo "音声のリリースへのアップロードに失敗しました。ニュース更新は継続します。" >&2
    fi

    AUDIO_DATES_FILE="$(mktemp "${TMPDIR:-/tmp}/ai-news-audio-assets.XXXXXX")"
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
        if git diff --cached --quiet; then
          echo "NotebookLM音声の変更はありません"
        elif git commit -m "$AUDIO_DATE のAIニュース音声を追加"; then
          git push origin main || echo "NotebookLM音声のpushに失敗しました。ニュース更新は継続します。" >&2
        else
          echo "NotebookLM音声のコミットに失敗しました。ニュース更新は継続します。" >&2
        fi
      fi
    fi
    rm -f "$AUDIO_DATES_FILE"

    if [ "$AUDIO_LOCAL_RETENTION_DAYS" -gt 0 ] && [ -d "$AUDIO_DIR" ]; then
      find "$AUDIO_DIR" -type f -name '*.m4a' -mtime +"$AUDIO_LOCAL_RETENTION_DAYS" -delete \
        || echo "ローカル音声の整理に失敗しました。ニュース更新は継続します。" >&2
    fi
  fi
  if [ "$IS_FALLBACK" -eq 1 ]; then
    LINE_MSG_MTIME_AFTER=0
    [ -f "$LINE_MSG_FILE" ] && LINE_MSG_MTIME_AFTER=$(stat -f %m "$LINE_MSG_FILE" 2>/dev/null || echo 0)
    LINE_MSG_HASH_AFTER=""
    [ -f "$LINE_MSG_FILE" ] && LINE_MSG_HASH_AFTER=$(md5 -q "$LINE_MSG_FILE" 2>/dev/null || echo "")
    if [ -s "$LINE_MSG_FILE" ] && { [ "$LINE_MSG_MTIME_AFTER" -gt "$LINE_MSG_MTIME_BEFORE" ] || [ "$LINE_MSG_HASH_AFTER" != "$LINE_MSG_HASH_BEFORE" ]; }; then
      # Codex実行時はline_message.txtの更新を検知するPostToolUseフック(.claude/hooks/line_notify.sh)が
      # 発火しないため、ここで明示的にLINE通知を送る。Claude成功時はフックに任せるため送らない。
      LINE_MSG="$(mark_as_codex_fallback "$(cat "$LINE_MSG_FILE")")"
      send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$LINE_MSG"
    fi
    osascript -e "display notification \"${SUMMARY_ESCAPED}（Codex経由）\" with title \"AIニュース更新\" sound name \"Glass\"" || true
  else
    osascript -e "display notification \"$SUMMARY_ESCAPED\" with title \"AIニュース更新\" sound name \"Glass\"" || true
  fi
else
  if [ "$IS_FALLBACK" -eq 1 ]; then
    osascript -e "display notification \"Claude利用上限到達 → Codexフォールバックも失敗しました\" with title \"AIニュース更新 失敗\" sound name \"Basso\"" || true
  else
    osascript -e "display notification \"daily_news.shが失敗しました。logs/daily_news.err.logを確認してください\" with title \"AIニュース更新 失敗\" sound name \"Basso\"" || true
  fi
fi

exit "$STATUS"
