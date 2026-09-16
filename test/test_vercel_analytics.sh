#!/usr/bin/env bash

set -euo pipefail

project_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
expected_pages=0

for page in "$project_root"/history/*.html; do
  expected_pages=$((expected_pages + 1))

  if ! rg -q '<script src="analytics\.js"></script>' "$page"; then
    echo "Analytics制御スクリプトの読み込みがありません: ${page#$project_root/}" >&2
    exit 1
  fi

  if rg -q 'src="https://cdn\.vercel-insights\.com/v1/script\.js"' "$page"; then
    echo "Vercel Analyticsスクリプトを直接読み込んでいます: ${page#$project_root/}" >&2
    exit 1
  fi
done

if [ "$expected_pages" -ne 6 ]; then
  echo "想定外のHTMLページ数です: $expected_pages" >&2
  exit 1
fi

echo "Vercel Analytics設定を ${expected_pages} ページで確認しました。"
