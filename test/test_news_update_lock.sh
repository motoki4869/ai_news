#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-news-lock-test.XXXXXX")"
trap 'rm -rf "$BASE_DIR"' EXIT

source "$REPO_DIR/scripts/lib/news_update_lock.sh"

if ! acquire_news_update_lock "$BASE_DIR"; then
  echo "最初のロック取得に失敗しました" >&2
  exit 1
fi

if acquire_news_update_lock "$BASE_DIR"; then
  echo "二重ロック取得を許可しました" >&2
  exit 1
fi

release_news_update_lock "$BASE_DIR"

if ! acquire_news_update_lock "$BASE_DIR"; then
  echo "解放後のロック再取得に失敗しました" >&2
  exit 1
fi

release_news_update_lock "$BASE_DIR"
echo "SUMMARY: ニュース更新ロックの取得・競合・解放を確認しました"
