#!/bin/bash
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/line_notification_dedupe.sh"

state_dir="${TMPDIR:-/tmp}/ai-news-line-notify-test-$$"
export LINE_NOTIFY_STATE_DIR="$state_dir"
export LINE_NOTIFY_DATE="2026-09-01"
export LINE_CHANNEL_ACCESS_TOKEN=test-token

stub_dir="${TMPDIR:-/tmp}/ai-news-line-notify-hook-test-$$"
failure_stub_dir="${TMPDIR:-/tmp}/ai-news-line-notify-hook-failure-$$"
hook_repo_dir="${TMPDIR:-/tmp}/ai-news-line-notify-hook-repo-$$"
uncommitted_state_dir="${TMPDIR:-/tmp}/ai-news-line-notify-hook-uncommitted-$$"
trap 'rm -rf "$state_dir" "$stub_dir" "$failure_stub_dir" "$hook_repo_dir" "$uncommitted_state_dir"' EXIT

mkdir -p "$hook_repo_dir/everyday_news"
git -C "$hook_repo_dir" init -q
git -C "$hook_repo_dir" config user.email test@example.com
git -C "$hook_repo_dir" config user.name test
cat > "$hook_repo_dir/everyday_news/202609.md" <<'EOF'
# 2026年9月 AIニュースまとめ

## 2026-09-03

## 2026-09-04
EOF
git -C "$hook_repo_dir" add everyday_news/202609.md
git -C "$hook_repo_dir" commit -q -m 'seed hook repo'

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
mkdir -p "$stub_dir"
ln -sf /usr/bin/true "$stub_dir/curl"
hook_state_dir="$stub_dir/state"
hook_input='{"tool_name":"Write","tool_input":{"file_path":"/repo/everyday_news/line_message.txt","content":"test message"}}'

run_hook() {
  local hook="$1"
  local target_state="${2:-$hook_state_dir}"
  local target_date="${3:-2026-09-03}"
  printf '%s' "$hook_input" | \
    PATH="$stub_dir:$PATH" \
    LINE_NOTIFY_REPO_DIR="$hook_repo_dir" \
    LINE_NOTIFY_STATE_DIR="$target_state" \
    LINE_NOTIFY_DATE="$target_date" \
    bash "$hook"
}

assert_status "Claudeフックの初回送信は許可される" 0 \
  run_hook "$script_dir/../../.claude/hooks/line_notify.sh"
assert_status "Codexフックの同日送信は抑止される" 0 \
  run_hook "$script_dir/../../.codex/hooks/line_notify.sh"

sent_count="$(find "$hook_state_dir" -type d -name '*.sent' -print 2>/dev/null | wc -l | tr -d ' ')"
assert_value "両フックで送信権が1つだけ作られる" "1" "$sent_count"

# HEADに当日見出しがない作業ツリーだけの更新はフックから送信しない。
printf '\n## 2026-09-05\n' >> "$hook_repo_dir/everyday_news/202609.md"
assert_status "未commit当日はフック送信を抑止する" 0 \
  run_hook "$script_dir/../../.claude/hooks/line_notify.sh" "$uncommitted_state_dir" "2026-09-05"
sent_count="$(find "$uncommitted_state_dir" -type d -name '*.sent' -print 2>/dev/null | wc -l | tr -d ' ')"
assert_value "未commit当日は送信claimを作らない" "0" "$sent_count"

# フックからのLINE送信が失敗した場合はclaimを解放し、同日再送を可能にする。
mkdir -p "$failure_stub_dir"
ln -sf /usr/bin/false "$failure_stub_dir/curl"
failure_state_dir="$failure_stub_dir/state"

run_failing_hook() {
  local hook="$1"
  printf '%s' "$hook_input" | \
    PATH="$failure_stub_dir:$PATH" \
    LINE_NOTIFY_STATE_DIR="$failure_state_dir" \
    LINE_NOTIFY_DATE="2026-09-04" \
    bash "$hook"
}

assert_status "Claudeフックの送信失敗は失敗扱いになる" 1 \
  run_failing_hook "$script_dir/../../.claude/hooks/line_notify.sh"
sent_count="$(find "$failure_state_dir" -type d -name '*.sent' -print 2>/dev/null | wc -l | tr -d ' ')"
assert_value "送信失敗時はclaimを残さない" "0" "$sent_count"
assert_status "送信失敗後は同日再送を再試行できる" 0 \
  run_hook "$script_dir/../../.claude/hooks/line_notify.sh" "$failure_state_dir" "2026-09-04"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
