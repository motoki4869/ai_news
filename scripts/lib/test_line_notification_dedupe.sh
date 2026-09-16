#!/bin/bash
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/line_notification_dedupe.sh"

state_dir="${TMPDIR:-/tmp}/ai-news-line-notify-test-$$"
export LINE_NOTIFY_STATE_DIR="$state_dir"
export LINE_NOTIFY_DATE="2026-09-01"

failures=0

assert_status() {
  local description="$1"
  local expected="$2"
  shift 2
  "$@"
  local actual=$?
  if [ "$actual" -ne "$expected" ]; then
    echo "FAIL: $description (expected $expected, got $actual)"
    failures=$((failures + 1))
  else
    echo "PASS: $description"
  fi
}

assert_value() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  if [ "$actual" != "$expected" ]; then
    echo "FAIL: $description (expected $expected, got $actual)"
    failures=$((failures + 1))
  else
    echo "PASS: $description"
  fi
}

# 通知文は「更新された日の日次ログ」へ直接着地させる。LINE_NOTIFY_DATEは
# 送信権の重複判定と同じ日付を使い、通知文とdedupeキーがずれないようにする。
assert_value "LINE通知は当日の日次ログURLを載せる" \
  "本日のAI_newsが更新されました

https://ai-news-sandy-seven.vercel.app/daily.html#2026-09-01" "$(line_notification_text)"

assert_value "LINE_NOTIFY_DATE未設定なら今日の日付を使う" \
  "https://ai-news-sandy-seven.vercel.app/daily.html#$(date +%Y-%m-%d)" \
  "$(LINE_NOTIFY_DATE= line_notification_text | tail -1)"

assert_status "同じ日・同じ通知対象は最初の1回だけ取得できる" 0 \
  claim_line_notification "/repo/everyday_news/line_message.txt"
assert_status "同じ日・同じ通知対象の2回目は抑止される" 1 \
  claim_line_notification "/repo/everyday_news/line_message.txt"

LINE_NOTIFY_DATE="2026-09-02" assert_status \
  "日付が変われば新しい通知を取得できる" 0 \
  claim_line_notification "/repo/everyday_news/line_message.txt"

# 両ランタイムのフックが共有状態を使い、同じ通知を1回に抑えることを確認する。
stub_dir="${TMPDIR:-/tmp}/ai-news-line-notify-hook-test-$$"
mkdir -p "$stub_dir"
ln -s /usr/bin/true "$stub_dir/curl"
hook_state_dir="$stub_dir/state"
hook_input='{"tool_name":"Write","tool_input":{"file_path":"/repo/everyday_news/line_message.txt","content":"test message"}}'

run_hook() {
  local hook="$1"
  printf '%s' "$hook_input" | \
    PATH="$stub_dir:$PATH" \
    LINE_NOTIFY_STATE_DIR="$hook_state_dir" \
    LINE_NOTIFY_DATE="2026-09-03" \
    bash "$hook"
}

assert_status "Claudeフックの初回送信は許可される" 0 \
  run_hook "$script_dir/../../.claude/hooks/line_notify.sh"
assert_status "Codexフックの同日送信は抑止される" 0 \
  run_hook "$script_dir/../../.codex/hooks/line_notify.sh"

sent_count="$(find "$hook_state_dir" -type d -name '*.sent' -print 2>/dev/null | wc -l | tr -d ' ')"
assert_value "両フックで送信権が1つだけ作られる" "1" "$sent_count"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
