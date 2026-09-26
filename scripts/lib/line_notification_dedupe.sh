#!/bin/bash

# 同じ通知対象を同じ日に複数回送らないための原子的な送信権取得。
# ClaudeフックとCodexフックの両方からsourceされる。

# 通知文と送信権の両方が同じ日付を見るようにする。片方だけdateを呼ぶと、
# 日付をまたぐ瞬間に「昨日のdedupeキーで今日のURLを送る」ようなずれが起きる。
line_notification_date() {
  printf '%s\n' "${LINE_NOTIFY_DATE:-$(date +%Y-%m-%d)}"
}

# ルートURL（70年史の年表）ではなく、その日の日次ログへ直接着地させる。
# daily.htmlはハッシュで日付を受け取るので、#YYYY-MM-DDを付ければ当日分が開く。
line_notification_text() {
  local message_file="${1:-}"
  local message=""
  local notification_date month day first_line
  notification_date="$(line_notification_date)"
  month=$((10#${notification_date:5:2}))
  day=$((10#${notification_date:8:2}))
  if [ -n "$message_file" ] && [ -s "$message_file" ]; then
    IFS= read -r first_line < "$message_file" || true
  fi
  if [ -n "$message_file" ] && [ -s "$message_file" ] \
     && [[ "$first_line" == *"${month}月${day}日"* ]]; then
    # LINEはMarkdownを描画しないため、line_message.txtの太字記号だけ取り除く。
    message="$(sed 's/\*\*//g' "$message_file")"
  fi
  if [ -z "$message" ]; then
    message="本日のAI_newsが更新されました"
  fi
  printf '%s\n\n🔗 今日のAIニュース\n%s\n' "$message" \
    "https://ai-news-sandy-seven.vercel.app/daily.html#$(line_notification_date)"
}

line_notification_error_detail() {
  local output="$1"
  local last_detail=""
  local last_line=""
  local line detail
  while IFS= read -r line; do
    case "$line" in
      SUMMARY:*) ;;
      *) [ -n "$line" ] && last_line="$line" ;;
    esac
    detail=""
    case "$line" in
      ERROR:\ \{*)
        detail="$(printf '%s\n' "${line#ERROR: }" | jq -r '.error.message // .message // empty' 2>/dev/null || true)"
        ;;
      ERROR:*|Error:*|error:*|fatal:*)
        detail="${line#*: }"
        ;;
    esac
    [ -n "$detail" ] && last_detail="$detail"
  done <<< "$output"
  printf '%s\n' "${last_detail:-$last_line}"
}

line_notification_failure_text() {
  local reason="$1"
  local status="$2"
  [ -n "$reason" ] || reason="詳細を特定できませんでした。daily_news.err.logを確認してください"
  printf '本日のAIニュース更新に失敗しました\n\n原因: %s\n終了コード: %s\n詳細ログ: logs/daily_news.err.log\n' \
    "$reason" "$status"
}

line_notification_error_claim_target() {
  local target_file="$1"
  local reason="$2"
  local reason_key
  reason_key="$(printf '%s\n' "$reason" | shasum -a 256 | awk '{print $1}')"
  printf '%s.error.%s\n' "$target_file" "$reason_key"
}

line_notification_state_dir() {
  printf '%s\n' "${LINE_NOTIFY_STATE_DIR:-${TMPDIR:-/tmp}/ai-news-line-notify}"
}

line_notification_claim_path() {
  local target_file="$1"
  local notification_date
  notification_date="$(line_notification_date)"
  local key
  # v2ではニュース本文を含む通知に切り替えた。旧版の固定文claimとは分離して、
  # 同日中に本文付き通知へ移行できるようにする。
  key="$(printf '%s\n%s\n%s\n' "$target_file" "$notification_date" 'line-notification-v2' | shasum -a 256 | awk '{print $1}')"
  printf '%s/%s.sent\n' "$(line_notification_state_dir)" "$key"
}

claim_line_notification() {
  local claim_path
  claim_path="$(line_notification_claim_path "$1")"

  if ! mkdir -p "$(dirname "$claim_path")"; then
    return 2
  fi

  # mkdirは原子的なので、並行実行でも最初の1プロセスだけが成功する。
  mkdir "$claim_path" 2>/dev/null
}

release_line_notification_claim() {
  local claim_path
  claim_path="$(line_notification_claim_path "$1")"
  rmdir "$claim_path" 2>/dev/null
}
