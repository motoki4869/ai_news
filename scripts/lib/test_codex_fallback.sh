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

result="$(mark_as_codex_fallback "テスト通知")"
assert_eq "マーカーが先頭に付与される" "⚠️Codex経由 テスト通知" "$result"

if [ "$fail" -ne 0 ]; then
  echo "FAILED"
  exit 1
fi
echo "ALL PASS"
exit 0
