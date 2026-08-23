#!/bin/bash
# Claude利用上限到達時にCodex CLI経由で処理を代替実行するための共通ヘルパー。
# investment・ai_news 両リポジトリに同一内容を複製配置している（意図的に非共有）。
# 呼び出し元スクリプトから `source` して使うこと。

is_claude_limit_reached() {
  local output="$1"
  echo "$output" | grep -qE "You've hit your (weekly|session) limit"
}

run_codex_fallback() {
  local repo_dir="$1"
  local prompt_file="$2"
  codex exec --skip-git-repo-check \
    -s workspace-write \
    -c sandbox_workspace_write.network_access=true \
    -C "$repo_dir" \
    "$(cat "$prompt_file")"
}

mark_as_codex_fallback() {
  local msg="$1"
  echo "⚠️Codex経由 ${msg}"
}

send_line_broadcast() {
  local settings_file="$1"
  local message="$2"
  local token
  token="${LINE_CHANNEL_ACCESS_TOKEN:-$(jq -r '.env.LINE_CHANNEL_ACCESS_TOKEN // empty' "$settings_file")}"
  local body
  body=$(jq -n --arg t "$message" '{messages:[{type:"text",text:$t}]}')
  curl -s -X POST https://api.line.me/v2/bot/message/broadcast \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "$body" >/dev/null
}
