#!/bin/bash
set -uo pipefail

REPO_DIR="/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.txt"
CODEX_PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.codex.txt"
CLAUDE_BIN="${CLAUDE_BIN:-/opt/homebrew/bin/claude}"
LINE_MSG_FILE="$REPO_DIR/everyday_news/line_message.txt"

cd "$REPO_DIR"

source "$REPO_DIR/scripts/lib/codex_fallback.sh"

LINE_MSG_MTIME_BEFORE=0
[ -f "$LINE_MSG_FILE" ] && LINE_MSG_MTIME_BEFORE=$(stat -f %m "$LINE_MSG_FILE" 2>/dev/null || echo 0)

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
  if [ "$IS_FALLBACK" -eq 1 ]; then
    LINE_MSG_MTIME_AFTER=0
    [ -f "$LINE_MSG_FILE" ] && LINE_MSG_MTIME_AFTER=$(stat -f %m "$LINE_MSG_FILE" 2>/dev/null || echo 0)
    if [ "$LINE_MSG_MTIME_AFTER" -gt "$LINE_MSG_MTIME_BEFORE" ] && [ -s "$LINE_MSG_FILE" ]; then
      # Codex実行時はline_message.txtの更新を検知するPostToolUseフック(.claude/hooks/line_notify.sh)が
      # 発火しないため、ここで明示的にLINE通知を送る。Claude成功時はフックに任せるため送らない。
      LINE_MSG="$(mark_as_codex_fallback "$(cat "$LINE_MSG_FILE")")"
      send_line_broadcast "$REPO_DIR/.claude/settings.local.json" "$LINE_MSG"
    fi
    osascript -e "display notification \"$SUMMARY_ESCAPED（Codex経由）\" with title \"AIニュース更新\" sound name \"Glass\"" || true
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
