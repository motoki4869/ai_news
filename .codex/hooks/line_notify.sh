#!/bin/bash
input=$(cat)
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/../../scripts/lib/line_notification_dedupe.sh"
source "$script_dir/../../scripts/lib/codex_fallback.sh"

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

# Write/Editの直後はまだcommit・push前なので、HEADに当日分が存在する場合だけ送る。
# 実送信は日次スクリプトのcommit確認後にも行うため、未公開のニュースを先に通知しない。
repo_dir="${LINE_NOTIFY_REPO_DIR:-$(cd "$script_dir/../.." && pwd)}"
notification_date="$(line_notification_date)"
source_file="everyday_news/${notification_date:0:4}${notification_date:5:2}.md"
if ! git -C "$repo_dir" show "HEAD:$source_file" 2>/dev/null \
  | grep -Eq "^##[[:space:]]+$notification_date([[:space:]].*)?$"; then
  exit 0
fi

# 同じ日の日次メッセージは、Write/Editが複数回行われても1回だけ送る。
claim_line_notification "$f" >/dev/null 2>&1 || exit 0

msg=$(line_notification_text)

if ! send_line_broadcast "$script_dir/../../.claude/settings.local.json" "$msg" 8 1; then
  release_line_notification_claim "$f" || true
  exit 1
fi
