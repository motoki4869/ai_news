#!/bin/bash
# 日次ニュース更新でCodex CLIとClaude Codeを起動するための共通ヘルパー。
# investment・ai_news 両リポジトリに同一内容を複製配置している（意図的に非共有）。
# 呼び出し元スクリプトから `source` して使うこと。
CODEX_FALLBACK_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

is_claude_limit_reached() {
  local output="$1"
  echo "$output" | grep -qE "You've hit your (weekly|session) limit"
}

is_codex_limit_reached() {
  local output="$1"
  grep -Eiq \
    "you['’]ve hit your usage limit|your workspace is out of credits|you hit your spend cap|workspace (owner|member) usage limit reached|usage_limit_exceeded|workspace(owner|member)(creditsdepleted|usagelimitreached)" \
    <<< "$output"
}

run_codex() {
  local repo_dir="$1"
  local prompt_file="$2"
  # launchdは.zshrcを読まずPATHが/usr/bin:/bin:/usr/sbin:/sbinに限られるため、
  # codexをPATH頼りで呼ぶと「command not found」(127)になりフォールバックが機能しない。
  # さらにcodexの実体は #!/usr/bin/env node のNodeスクリプトなので、codexのパスを
  # 解決しただけでは `env: node: No such file or directory` (127) で落ちる。
  # そこで codex と node の両方を明示的に解決し、node のあるディレクトリを PATH の
  # 先頭に足してから起動する（codexが内部で起動する子プロセスもnodeを見つけられるように）。
  local codex_bin="${CODEX_BIN:-}"
  if [ -z "$codex_bin" ]; then
    # launchdのPATHから見つかるHomebrew版より、モデル一覧が新しいデスクトップ同梱版を優先する。
    for candidate in /Applications/ChatGPT.app/Contents/Resources/codex "$(command -v codex || true)" /opt/homebrew/bin/codex /usr/local/bin/codex; do
      [ -n "$candidate" ] && [ -x "$candidate" ] && codex_bin="$candidate" && break
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

  # model/listから利用可能なSolモデルを確認し、数値バージョンが最新のものを選ぶ。
  # app-server照会に失敗した場合も日次処理を止めないよう、現アプリで確認済みのモデルへ戻す。
  local fallback_model="${CODEX_FALLBACK_MODEL:-gpt-6-sol}"
  if [ -z "${CODEX_FALLBACK_MODEL:-}" ]; then
    local model_list
    local python_bin="${PYTHON_BIN:-$(command -v python3 || true)}"
    if [ ! -x "$python_bin" ]; then
      for candidate in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
        [ -x "$candidate" ] && python_bin="$candidate" && break
      done
    fi
    if [ ! -x "$python_bin" ]; then
      echo "python3コマンドが見つからないため、Codexのモデル一覧を取得できません。$fallback_model を使用します" >&2
    elif model_list=$(PATH="$(dirname "$node_bin"):$PATH" \
      CODEX_MODEL_LIST_TIMEOUT_SECONDS="${CODEX_MODEL_LIST_TIMEOUT_SECONDS:-5}" \
      "$python_bin" "$CODEX_FALLBACK_LIB_DIR/resolve_codex_models.py" "$codex_bin" "latest-sol" 2>&1); then
      if [[ "$model_list" =~ ^gpt-[0-9]+(\.[0-9]+)*-sol$ ]]; then
        fallback_model="$model_list"
      else
        echo "CodexのSolモデル一覧から有効なモデルIDを選べないため、$fallback_model を使用します: $model_list" >&2
      fi
    else
      echo "CodexのSolモデル一覧を取得できないため、$fallback_model を使用します: $model_list" >&2
    fi
  fi

  local attempt_log
  attempt_log=$(mktemp "${TMPDIR:-/tmp}/ai-news-codex-fallback.XXXXXX") || return 1
  local agent_bin_dir="$CODEX_FALLBACK_LIB_DIR/../agent-bin"
  local real_git_bin="${AI_NEWS_REAL_GIT:-$(command -v git || true)}"
  echo "Codex実行モデル: $fallback_model" >&2
  PATH="$agent_bin_dir:$(dirname "$node_bin"):$PATH" \
    AI_NEWS_REAL_GIT="$real_git_bin" \
    "$codex_bin" exec --skip-git-repo-check \
    -m "$fallback_model" \
    -s workspace-write \
    -c sandbox_workspace_write.network_access=true \
    -C "$repo_dir" \
    "$(cat "$prompt_file")" 2>&1 | tee "$attempt_log"
  local status=${PIPESTATUS[0]}
  rm -f "$attempt_log"
  return "$status"
}

mark_as_codex_fallback() {
  local msg="$1"
  echo "⚠️Codex経由 ${msg}"
}

run_claude_fallback() {
  local repo_dir="$1"
  local prompt_file="$2"
  local claude_bin="${3:-${CLAUDE_BIN:-/opt/homebrew/bin/claude}}"
  if [ ! -x "$claude_bin" ]; then
    echo "Claude Codeコマンドが見つからないため、フォールバックを実行できません: $claude_bin" >&2
    return 127
  fi

  # launchdのPATHにはnodeが含まれないため、Claude CodeのCLIからも使えるよう補う。
  local node_bin="${NODE_BIN:-$(command -v node || true)}"
  if [ ! -x "$node_bin" ]; then
    for candidate in /opt/homebrew/bin/node /usr/local/bin/node; do
      [ -x "$candidate" ] && node_bin="$candidate" && break
    done
  fi
  if [ ! -x "$node_bin" ]; then
    echo "nodeコマンドが見つからないため、Claude Codeフォールバックを実行できません" >&2
    return 127
  fi

  cd "$repo_dir" || return 1
  local agent_bin_dir="$CODEX_FALLBACK_LIB_DIR/../agent-bin"
  local real_git_bin="${AI_NEWS_REAL_GIT:-$(command -v git || true)}"
  PATH="$agent_bin_dir:$(dirname "$node_bin"):$PATH" \
    AI_NEWS_REAL_GIT="$real_git_bin" \
    "$claude_bin" -p "$(cat "$prompt_file")" \
    --allowedTools "Read Write Edit WebSearch Bash" 2>&1
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
