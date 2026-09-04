#!/bin/bash

# 同じ通知対象を同じ日に複数回送らないための原子的な送信権取得。
# ClaudeフックとCodexフックの両方からsourceされる。

line_notification_text() {
  printf '%s\n' "本日のAI_newsが更新されました"
}

line_notification_state_dir() {
  printf '%s\n' "${LINE_NOTIFY_STATE_DIR:-${TMPDIR:-/tmp}/ai-news-line-notify}"
}

line_notification_claim_path() {
  local target_file="$1"
  local notification_date="${LINE_NOTIFY_DATE:-$(date +%Y-%m-%d)}"
  local key
  key="$(printf '%s\n%s\n' "$target_file" "$notification_date" | shasum -a 256 | awk '{print $1}')"
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
