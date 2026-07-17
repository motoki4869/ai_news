#!/bin/bash
input=$(cat)
f=$(echo "$input" | jq -r '.tool_response.filePath // .tool_input.file_path // empty')

case "$f" in
  */everyday_news/*) ;;
  *) exit 0 ;;
esac

tool=$(echo "$input" | jq -r '.tool_name')

if [ "$tool" = "Edit" ]; then
  old=$(echo "$input" | jq -r '.tool_input.old_string // empty')
  new=$(echo "$input" | jq -r '.tool_input.new_string // empty')
  added=$(diff <(printf '%s\n' "$old") <(printf '%s\n' "$new") | grep '^>' | sed 's/^> //')
else
  added=$(echo "$input" | jq -r '.tool_input.content // empty')
fi

[ -z "$added" ] && exit 0

formatted=$(printf '%s\n' "$added" | perl -Mutf8 -CSD -ne '
if (/^-\s*\*\*(.+?)\*\*[:：]\s*(.*?)\x{FF08}\[出典\]\((https?:\/\/[^\)]+)\)\x{FF09}。?\s*$/) {
  print "◆ $1\n$2\n出典: $3\n\n";
} elsif (/\S/) {
  print "$_\n";
}
')
formatted=$(printf '%s' "$formatted" | cut -c1-3500)

msg="📰 AIニュース更新: $(basename "$f")
---
$formatted"

msg=$(printf '%s' "$msg" | cut -c1-4900)

body=$(jq -n --arg t "$msg" '{messages:[{type:"text",text:$t}]}')
curl -s -X POST https://api.line.me/v2/bot/message/broadcast \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LINE_CHANNEL_ACCESS_TOKEN" \
  -d "$body" >/dev/null
