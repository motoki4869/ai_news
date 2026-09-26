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
  # launchdは.zshrcを読まずPATHが/usr/bin:/bin:/usr/sbin:/sbinに限られるため、
  # codexをPATH頼りで呼ぶと「command not found」(127)になりフォールバックが機能しない。
  # さらにcodexの実体は #!/usr/bin/env node のNodeスクリプトなので、codexのパスを
  # 解決しただけでは `env: node: No such file or directory` (127) で落ちる。
  # そこで codex と node の両方を明示的に解決し、node のあるディレクトリを PATH の
  # 先頭に足してから起動する（codexが内部で起動する子プロセスもnodeを見つけられるように）。
  local codex_bin="${CODEX_BIN:-$(command -v codex || true)}"
  if [ ! -x "$codex_bin" ]; then
    for candidate in /opt/homebrew/bin/codex /usr/local/bin/codex; do
      [ -x "$candidate" ] && codex_bin="$candidate" && break
    done
  fi
  if [ ! -x "$codex_bin" ]; then
    echo "codexコマンドが見つからないため、Codexフォールバックを実行できません" >&2
    return 127
  fi

  local node_bin="${NODE_BIN:-$(command -v node || true)}"
  if [ ! -x "$node_bin" ]; then
    for candidate in /opt/homebrew/bin/node /usr/local/bin/node; do
      [ -x "$candidate" ] && node_bin="$candidate" && break
    done
  fi
  if [ ! -x "$node_bin" ]; then
    echo "nodeコマンドが見つからないため、Codexフォールバックを実行できません" >&2
    return 127
  fi

  # アカウントやCodex CLIの更新で利用可能なモデルが変わるため、固定名は使わず
  # app-serverのmodel/listから現在利用可能な候補を取得する。環境変数は候補内に
  # 存在するときだけ優先指定として使い、通常はAPIが示すデフォルトを先頭にする。
  local resolver="$(dirname "${BASH_SOURCE[0]}")/resolve_codex_models.py"
  local preferred_model="${CODEX_FALLBACK_MODEL:-}"
  local candidate_output
  candidate_output=$(PATH="$(dirname "$node_bin"):$PATH" python3 "$resolver" "$codex_bin" "$preferred_model") || {
    echo "Codexの利用可能モデル一覧を取得できず、フォールバックを開始できません" >&2
    return 1
  }
  local candidates=()
  while IFS= read -r model; do
    [ -n "$model" ] && candidates+=("$model")
  done <<< "$candidate_output"
  if [ "${#candidates[@]}" -eq 0 ]; then
    echo "Codexの利用可能モデル一覧が空のため、フォールバックを開始できません" >&2
    return 1
  fi

  local attempt_log
  attempt_log=$(mktemp "${TMPDIR:-/tmp}/ai-news-codex-fallback.XXXXXX") || return 1
  local status=1
  local fallback_model
  for fallback_model in "${candidates[@]}"; do
    echo "Codexフォールバックモデル: $fallback_model" >&2
    PATH="$(dirname "$node_bin"):$PATH" "$codex_bin" exec --skip-git-repo-check \
      -m "$fallback_model" \
      -s workspace-write \
      -c sandbox_workspace_write.network_access=true \
      -C "$repo_dir" \
      "$(cat "$prompt_file")" 2>&1 | tee "$attempt_log"
    status=${PIPESTATUS[0]}
    [ "$status" -eq 0 ] && break

    if ! grep -qiE "model.*(not supported|unsupported|not found)|not supported.*model" "$attempt_log"; then
      break
    fi
    echo "モデル $fallback_model は実行時に利用不可でした。次の候補を試します。" >&2
  done
  rm -f "$attempt_log"
  return "$status"
}

mark_as_codex_fallback() {
  local msg="$1"
  echo "⚠️Codex経由 ${msg}"
}

send_line_broadcast() {
  local settings_file="$1"
  local message="$2"
  local max_time="${3:-20}"
  local retry_count="${4:-2}"
  local token
  token="${LINE_CHANNEL_ACCESS_TOKEN:-$(jq -r '.env.LINE_CHANNEL_ACCESS_TOKEN // empty' "$settings_file")}"
  local body
  body=$(jq -n --arg t "$message" '{messages:[{type:"text",text:$t}]}')
  curl -fsS --max-time "$max_time" --retry "$retry_count" --retry-delay 1 \
    -X POST https://api.line.me/v2/bot/message/broadcast \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "$body" >/dev/null
}
