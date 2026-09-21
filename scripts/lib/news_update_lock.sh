#!/bin/bash

# 日次・週次のニュース更新が同じ原本・生成物・Git indexを同時に変更しないためのロック。
# 日次スクリプトはプロセス所有ロック、エージェントが複数のBash呼び出しにまたがって
# 実行する週次処理は期限付きleaseを使う。

NEWS_UPDATE_LOCK_TTL_SECONDS="${NEWS_UPDATE_LOCK_TTL_SECONDS:-21600}"

_news_update_lock_dir() {
  printf '%s/.news-update.lock\n' "${1%/}"
}

_news_update_lock_owner_file() {
  printf '%s/owner\n' "$(_news_update_lock_dir "$1")"
}

_news_update_lock_field() {
  local field="$1"
  local owner_file="$2"
  sed -n "s/^${field}=//p" "$owner_file" 2>/dev/null | sed -n '1p'
}

_news_update_lock_token() {
  printf '%s-%s-%s\n' "$$" "$(date +%s)" "${RANDOM:-0}"
}

_news_update_process_start() {
  ps -p "$1" -o lstart= 2>/dev/null | sed 's/^ *//'
}

_news_update_write_owner() {
  local lock_dir="$1"
  local mode="$2"
  local token="$3"
  local owner_file="$lock_dir/owner"
  local temporary="$lock_dir/.owner.$$"
  local now process_start
  now="$(date +%s)"
  process_start="$(_news_update_process_start $$)"
  [ -n "$process_start" ] || process_start="unavailable"

  {
    printf 'mode=%s\n' "$mode"
    printf 'pid=%s\n' "$$"
    printf 'process_start=%s\n' "$process_start"
    printf 'acquired_at=%s\n' "$now"
    printf 'renewed_at=%s\n' "$now"
    printf 'token=%s\n' "$token"
  } > "$temporary" && mv "$temporary" "$owner_file"
}

_news_update_lock_is_stale() {
  local repo_dir="$1"
  local owner_file="$(_news_update_lock_owner_file "$repo_dir")"
  local mode pid process_start renewed_at now

  [ -f "$owner_file" ] || return 1
  mode="$(_news_update_lock_field mode "$owner_file")"
  pid="$(_news_update_lock_field pid "$owner_file")"
  process_start="$(_news_update_lock_field process_start "$owner_file")"
  renewed_at="$(_news_update_lock_field renewed_at "$owner_file")"
  now="$(date +%s)"

  if [ "$mode" = "lease" ]; then
    [ -n "$renewed_at" ] || return 0
    [ $((now - renewed_at)) -gt "$NEWS_UPDATE_LOCK_TTL_SECONDS" ]
    return $?
  fi

  if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
    return 0
  fi
  if [ "$process_start" = "unavailable" ]; then
    return 1
  fi
  if [ -z "$process_start" ] || [ "$(_news_update_process_start "$pid")" != "$process_start" ]; then
    return 0
  fi
  return 1
}

_news_update_reclaim_stale_lock() {
  local repo_dir="$1"
  local lock_dir="$(_news_update_lock_dir "$repo_dir")"
  local stale_dir="${lock_dir}.stale.$$-${RANDOM:-0}"

  _news_update_lock_is_stale "$repo_dir" || return 1
  if ! mv "$lock_dir" "$stale_dir" 2>/dev/null; then
    return 1
  fi
  rm -f "$stale_dir/owner" "$stale_dir"/.owner.*
  rmdir "$stale_dir" 2>/dev/null || true
  return 0
}

acquire_news_update_lock() {
  local repo_dir="$1"
  local requested_mode="${2:-process}"
  local mode="process"
  local lock_dir
  local token

  [ "$requested_mode" = "--lease" ] && mode="lease"
  lock_dir="$(_news_update_lock_dir "$repo_dir")"
  token="$(_news_update_lock_token)"

  if ! mkdir "$lock_dir" 2>/dev/null; then
    _news_update_reclaim_stale_lock "$repo_dir" || {
      echo "ニュース更新ロックを取得できません: $lock_dir" >&2
      return 1
    }
    if ! mkdir "$lock_dir" 2>/dev/null; then
      echo "ニュース更新ロックを取得できません: $lock_dir" >&2
      return 1
    fi
  fi

  if ! _news_update_write_owner "$lock_dir" "$mode" "$token"; then
    rmdir "$lock_dir" 2>/dev/null || true
    echo "ニュース更新ロックの所有情報を書き込めません: $lock_dir" >&2
    return 1
  fi

  NEWS_UPDATE_LOCK_DIR="$lock_dir"
  NEWS_UPDATE_LOCK_TOKEN="$token"
  if [ "$mode" = "lease" ]; then
    printf '%s\n' "$token"
  fi
}

refresh_news_update_lock() {
  local repo_dir="$1"
  local token="$2"
  local lock_dir="$(_news_update_lock_dir "$repo_dir")"
  local owner_file="$lock_dir/owner"
  local actual_token temporary
  actual_token="$(_news_update_lock_field token "$owner_file")"
  [ -n "$token" ] && [ "$token" = "$actual_token" ] || return 1

  temporary="$lock_dir/.owner.$$"
  sed "s/^renewed_at=.*/renewed_at=$(date +%s)/" "$owner_file" > "$temporary" || return 1
  mv "$temporary" "$owner_file"
}

release_news_update_lock() {
  local repo_dir="$1"
  local expected_token="${2:-${NEWS_UPDATE_LOCK_TOKEN:-}}"
  local lock_dir="$(_news_update_lock_dir "$repo_dir")"
  local owner_file="$lock_dir/owner"
  local actual_token

  actual_token="$(_news_update_lock_field token "$owner_file")"
  if [ -z "$expected_token" ] || [ "$expected_token" != "$actual_token" ]; then
    echo "ニュース更新ロックの所有者ではないため解放しません: $lock_dir" >&2
    return 1
  fi

  rm -f "$owner_file" "$lock_dir/.owner.$$"
  if ! rmdir "$lock_dir" 2>/dev/null; then
    return 1
  fi
  if [ "${NEWS_UPDATE_LOCK_TOKEN:-}" = "$expected_token" ]; then
    unset NEWS_UPDATE_LOCK_DIR NEWS_UPDATE_LOCK_TOKEN
  fi
}
