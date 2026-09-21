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

OWNER_TOKEN="$NEWS_UPDATE_LOCK_TOKEN"

if release_news_update_lock "$BASE_DIR" "wrong-owner"; then
  echo "非所有者のロック解放を許可しました" >&2
  exit 1
fi

if [ ! -d "$BASE_DIR/.news-update.lock" ]; then
  echo "非所有者の解放でロックを削除しました" >&2
  exit 1
fi

if acquire_news_update_lock "$BASE_DIR"; then
  echo "二重ロック取得を許可しました" >&2
  exit 1
fi

release_news_update_lock "$BASE_DIR" "$OWNER_TOKEN"

if ! acquire_news_update_lock "$BASE_DIR"; then
  echo "解放後のロック再取得に失敗しました" >&2
  exit 1
fi
PROCESS_TOKEN="$NEWS_UPDATE_LOCK_TOKEN"
release_news_update_lock "$BASE_DIR" "$PROCESS_TOKEN"

LEASE_TOKEN_FILE="$BASE_DIR/lease-token"
if ! acquire_news_update_lock "$BASE_DIR" --lease > "$LEASE_TOKEN_FILE"; then
  echo "leaseロックの取得に失敗しました" >&2
  exit 1
fi
LEASE_TOKEN="$(sed -n '1p' "$LEASE_TOKEN_FILE")"
if [ -z "$LEASE_TOKEN" ]; then
  echo "leaseトークンを取得できませんでした" >&2
  exit 1
fi
if release_news_update_lock "$BASE_DIR" "$OWNER_TOKEN"; then
  echo "古い所有者トークンでleaseを解放しました" >&2
  exit 1
fi
if ! refresh_news_update_lock "$BASE_DIR" "$LEASE_TOKEN"; then
  echo "leaseの更新に失敗しました" >&2
  exit 1
fi
release_news_update_lock "$BASE_DIR" "$LEASE_TOKEN"

if [ -d "$BASE_DIR/.news-update.lock" ]; then
  echo "lease解放後もロックが残っています" >&2
  exit 1
fi

mkdir "$BASE_DIR/.news-update.lock"
cat > "$BASE_DIR/.news-update.lock/owner" <<'EOF'
mode=process
pid=99999999
process_start=unavailable
acquired_at=1
renewed_at=1
token=dead-owner
EOF
if ! acquire_news_update_lock "$BASE_DIR"; then
  echo "staleロックを回収できませんでした" >&2
  exit 1
fi
release_news_update_lock "$BASE_DIR" "$NEWS_UPDATE_LOCK_TOKEN"

mkdir "$BASE_DIR/.news-update.lock"
touch -t 200001010000 "$BASE_DIR/.news-update.lock"
if ! acquire_news_update_lock "$BASE_DIR"; then
  echo "ownerファイルがないstaleロックを回収できませんでした" >&2
  exit 1
fi
release_news_update_lock "$BASE_DIR" "$NEWS_UPDATE_LOCK_TOKEN"
echo "SUMMARY: ニュース更新ロックの取得・競合・解放を確認しました"
