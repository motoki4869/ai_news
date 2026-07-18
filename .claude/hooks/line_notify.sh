#!/bin/bash
input=$(cat)
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

msg=$(printf '%s' "$msg" | cut -c1-4900)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
token="${LINE_CHANNEL_ACCESS_TOKEN:-$(jq -r '.env.LINE_CHANNEL_ACCESS_TOKEN // empty' "$script_dir/../settings.local.json")}"

body=$(jq -n --arg t "$msg" '{messages:[{type:"text",text:$t}]}')
curl -s -X POST https://api.line.me/v2/bot/message/broadcast \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $token" \
  -d "$body" >/dev/null
