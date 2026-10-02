#!/bin/bash
# 長い日次実行ログから行頭一致する行を確認する。
# printf | grep -q は pipefail 有効時に grep の早期終了で printf が SIGPIPE となる。
has_output_line_prefix() {
  local output="$1"
  local prefix="$2"
  [[ "$output" == "$prefix"* || "$output" == *$'\n'"$prefix"* ]]
}
