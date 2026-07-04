#!/bin/bash
set -euo pipefail

REPO_DIR="/Users/motoki/Desktop/GitHub/ai_news"
PROMPT_FILE="$REPO_DIR/scripts/daily_news_prompt.txt"
CLAUDE_BIN="/opt/homebrew/bin/claude"

cd "$REPO_DIR"

"$CLAUDE_BIN" -p "$(cat "$PROMPT_FILE")" \
  --allowedTools "Read Write Edit WebSearch Bash"
