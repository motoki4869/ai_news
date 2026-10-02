#!/bin/bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/daily_news_output.sh"

failures=0
assert_status() {
  local description="$1" expected="$2"
  shift 2
  "$@"
  local actual=$?
  if [ "$actual" -eq "$expected" ]; then
    echo "PASS: $description"
  else
    echo "FAIL: $description (expected $expected, got $actual)"
    failures=$((failures + 1))
  fi
}

newline=$'\n'
long_output="前のログ${newline}SUMMARY: OK: 更新完了${newline}$(printf '%*s' 262144 '')"
error_output="ログ${newline}SUMMARY: ERROR: 失敗"
other_line="ログ${newline}別の行"

assert_status "出力先頭のSUMMARY: OKを認識する" 0 \
  has_output_line_prefix "SUMMARY: OK: 更新完了" "SUMMARY: OK:"
assert_status "大量の後続ログがあってもSUMMARY: OKを認識する" 0 \
  has_output_line_prefix "$long_output" "SUMMARY: OK:"
assert_status "改行後のSUMMARY: ERRORを認識する" 0 \
  has_output_line_prefix "$error_output" "SUMMARY: ERROR:"
assert_status "行途中にあるSUMMARY文字列は認識しない" 1 \
  has_output_line_prefix "ログにSUMMARY: OK:が含まれる" "SUMMARY: OK:"
assert_status "Summary以外の行頭は認識しない" 1 \
  has_output_line_prefix "$other_line" "SUMMARY: OK:"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
echo "ALL PASS"
