#!/bin/bash

# 日次・週次のニュース更新が同じ原本・生成物・Git indexを同時に変更しないためのロック。
# mkdirは同時実行時にも原子的に成功するため、ロック取得の判定に使う。

acquire_news_update_lock() {
  local repo_dir="$1"
  local lock_dir="${repo_dir%/}/.news-update.lock"
  local owner_pid

  if mkdir "$lock_dir" 2>/dev/null; then
    printf '%s\n' "$$" > "$lock_dir/pid"
    NEWS_UPDATE_LOCK_DIR="$lock_dir"
    return 0
  fi

  if [ -f "$lock_dir/pid" ]; then
    owner_pid="$(sed -n '1p' "$lock_dir/pid" 2>/dev/null || true)"
    if [ -n "$owner_pid" ] && ! kill -0 "$owner_pid" 2>/dev/null; then
      rm -f "$lock_dir/pid"
      if rmdir "$lock_dir" 2>/dev/null; then
        acquire_news_update_lock "$repo_dir"
        return $?
      fi
    fi
  fi

  echo "ニュース更新ロックを取得できません: $lock_dir" >&2
  return 1
}

release_news_update_lock() {
  local repo_dir="$1"
  local lock_dir="${NEWS_UPDATE_LOCK_DIR:-${repo_dir%/}/.news-update.lock}"

  rm -f "$lock_dir/pid"
  rmdir "$lock_dir" 2>/dev/null || true
  unset NEWS_UPDATE_LOCK_DIR
}
