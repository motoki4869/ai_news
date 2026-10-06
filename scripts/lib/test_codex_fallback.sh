#!/bin/bash
# scripts/lib/codex_fallback.sh の簡易テスト。
# このリポジトリにシェル用テストフレームワークが無いため、フレームワーク非依存の
# 自作アサーションで代替する。ネットワークI/O(send_line_broadcast)は対象外。
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/codex_fallback.sh"

fail=0

assert_true() {
  local desc="$1"; shift
  if "$@"; then echo "ok - $desc"; else echo "NG - $desc"; fail=1; fi
}

assert_false() {
  local desc="$1"; shift
  if "$@"; then echo "NG - $desc"; fail=1; else echo "ok - $desc"; fi
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "ok - $desc"
  else
    echo "NG - $desc (expected: [$expected], actual: [$actual])"
    fail=1
  fi
}

assert_true "weekly limitの文字列を検出できる" is_claude_limit_reached "You've hit your weekly limit · resets 10pm (Asia/Tokyo)"
assert_true "session limitの文字列を検出できる" is_claude_limit_reached "You've hit your session limit · resets 10:10am (Asia/Tokyo)"
assert_false "通常のエラー文字列では検出しない" is_claude_limit_reached "Error: network timeout"
assert_false "空文字列では検出しない" is_claude_limit_reached ""
assert_true "標準的なCodex利用上限を検出できる" is_codex_limit_reached "ERROR: You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage"
assert_true "モデル別のCodex利用上限を検出できる" is_codex_limit_reached "You've hit your usage limit for gpt-5.6. Switch to another model now"
assert_true "Codex workspace credit切れを検出できる" is_codex_limit_reached "Your workspace is out of credits. Add credits to continue."
assert_true "Codex workspace spend capを検出できる" is_codex_limit_reached "You hit your spend cap set in your workspace."
assert_true "Codex内部エラーコードを検出できる" is_codex_limit_reached "usage_limit_exceeded"
assert_false "一般的な通信エラーはCodex利用上限として誤検出しない" is_codex_limit_reached "Error: network timeout"
long_output="$(printf 'usage_limit_exceeded\n'; printf '%*s' 262144 '' | tr ' ' x)"
assert_true "長いログの先頭にあるCodex利用上限も検出できる" is_codex_limit_reached "$long_output"

result="$(mark_as_codex_fallback "テスト通知")"
assert_eq "マーカーが先頭に付与される" "⚠️Codex経由 テスト通知" "$result"

test_dir="$(mktemp -d "${TMPDIR:-/tmp}/test-codex-fallback.XXXXXX")"
test_dir="$(cd "$test_dir" && pwd -P)"
mkdir -p "$test_dir/codex-home"
printf '{}\n' > "$test_dir/codex-home/auth.json"
cleanup_test_dir() {
  find "$test_dir" -type f -delete
  find "$test_dir" -depth -type d -exec rmdir {} +
}
trap cleanup_test_dir EXIT
cat > "$test_dir/codex" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >> "$CODEX_ARGS_LOG"
SH
chmod +x "$test_dir/codex"
printf 'test prompt\n' > "$test_dir/prompt.txt"
CODEX_ARGS_LOG="$test_dir/args.log" \
CODEX_HOME="$test_dir/codex-home" \
CODEX_BIN="$test_dir/codex" \
NODE_BIN="$(command -v node || command -v python3)" \
CODEX_FALLBACK_MODEL="gpt-6.1-sol" \
run_codex "$test_dir" "$test_dir/prompt.txt" "$test_dir/real-repo" >/dev/null 2>&1
assert_true "環境変数で指定したCodexモデルを利用する" grep -q -- '-m gpt-6.1-sol' "$test_dir/args.log"
assert_true "外側のSeatbelt内でCodexの内側のsandboxを無効にする" grep -q -- '-s danger-full-access -c approval_policy=never' "$test_dir/args.log"
assert_true "最新ニュース用のWeb検索を有効にする" grep -q -- 'web_search=live' "$test_dir/args.log"
assert_true "通常のCodex設定と追加アプリを読み込まない" grep -q -- '--ignore-user-config --ephemeral' "$test_dir/args.log"
assert_false "モデルを明示指定した場合は一覧取得を省略する" grep -Eq 'app-server|model/list' "$test_dir/args.log"

cat > "$test_dir/node" <<'SH'
#!/bin/bash
exit 0
SH
chmod +x "$test_dir/node"
cat > "$test_dir/codex-model-server" <<'SH'
#!/bin/bash
if [ "$1" = app-server ]; then
  printf 'node=%s\n' "$(command -v node || true)" >> "$CODEX_ARGS_LOG"
  count=0
  while [ "$count" -lt 3 ] && IFS= read -r _; do
    count=$((count + 1))
  done
  printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"data":[{"id":"gpt-6-sol"},{"id":"gpt-6.1-sol"}]}}'
  while :; do sleep 1; done
fi
printf '%s\n' "$*" >> "$CODEX_ARGS_LOG"
SH
chmod +x "$test_dir/codex-model-server"
: > "$test_dir/args.log"
PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
CODEX_ARGS_LOG="$test_dir/args.log" \
CODEX_HOME="$test_dir/codex-home" \
CODEX_BIN="$test_dir/codex-model-server" \
NODE_BIN="$test_dir/node" \
CODEX_FALLBACK_MODEL="" \
run_codex "$test_dir" "$test_dir/prompt.txt" "$test_dir/real-repo" >/dev/null 2>&1
assert_true "launchd相当のPATHでもapp-serverから最新Solを選ぶ" grep -q -- '-m gpt-6.1-sol' "$test_dir/args.log"
assert_true "model/list用app-serverからnodeを解決できるPATHを渡す" grep -q "node=$test_dir/node" "$test_dir/args.log"

if [ "$fail" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASS"
exit 0
