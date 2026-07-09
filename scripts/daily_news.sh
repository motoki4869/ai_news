#!/bin/bash
set -uo pipefail

REPO_DIR="/Users/motoki/Desktop/GitHub/ai_news"
PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.txt"
CLAUDE_BIN="/opt/homebrew/bin/claude"

cd "$REPO_DIR"

OUTPUT="$("$CLAUDE_BIN" -p "$(cat "$PROMPT_FILE")" \
  --allowedTools "Read Write Edit WebSearch Bash" 2>&1)"
STATUS=$?

echo "$OUTPUT"

SUMMARY="$(echo "$OUTPUT" | grep '^SUMMARY:' | tail -1 | sed 's/^SUMMARY: *//')"
SUMMARY="${SUMMARY:-ニュースを更新しました}"
# AppleScript文字列リテラルに埋め込むため \ と " をエスケープし、通知の表示上限に合わせて短く切る
SUMMARY_ESCAPED="$(printf '%s' "$SUMMARY" | cut -c1-200 | sed 's/\\/\\\\/g; s/"/\\"/g')"

if [ "$STATUS" -eq 0 ]; then
  osascript -e "display notification \"$SUMMARY_ESCAPED\" with title \"AIニュース更新\" sound name \"Glass\"" || true
else
  osascript -e "display notification \"daily_news.shが失敗しました。logs/daily_news.err.logを確認してください\" with title \"AIニュース更新 失敗\" sound name \"Basso\"" || true
fi

exit "$STATUS"
