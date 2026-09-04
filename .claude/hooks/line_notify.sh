#!/bin/bash
input=$(cat)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/../../scripts/lib/line_notification_dedupe.sh"

f=$(echo "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')

case "$f" in
  */everyday_news/line_message.txt) ;;
  *) exit 0 ;;
esac

tool=$(echo "$input" | jq -r '.tool_name')

if [ "$tool" = "Edit" ]; then
  msg=$(echo "$input" | jq -r '.tool_input.new_string // empty')
else
  msg=$(echo "$input" | jq -r '.tool_input.content // empty')
fi

[ -z "$msg" ] && exit 0

# 同じ日の日次メッセージは、Write/Editが複数回行われても1回だけ送る。
claim_line_notification "$f" >/dev/null 2>&1 || exit 0

msg=$(line_notification_text)

token="${LINE_CHANNEL_ACCESS_TOKEN:-$(jq -r '.env.LINE_CHANNEL_ACCESS_TOKEN // empty' "$script_dir/../settings.local.json")}"

body=$(jq -n --arg t "$msg" '{messages:[{type:"text",text:$t}]}')
curl -s -X POST https://api.line.me/v2/bot/message/broadcast \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d "$body" >/dev/null
