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
  local original_repo_dir="${3:-$repo_dir}"
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

  local auth_source="${CODEX_HOME:-$HOME/.codex}/auth.json"
  local runtime_dir runtime_home runtime_codex_home runtime_tmp
  runtime_dir="$(mktemp -d "$repo_dir/.codex-runtime.XXXXXX")" || return 1
  runtime_home="$runtime_dir/home"
  runtime_codex_home="$runtime_home/.codex"
  runtime_tmp="$runtime_dir/tmp"
  mkdir -p "$runtime_codex_home" "$runtime_tmp" || return 1
  local attempt_log
  attempt_log=$(mktemp "${TMPDIR:-/tmp}/ai-news-codex-fallback.XXXXXX") || return 1
  cd "$repo_dir" || return 1
  if ! cp "$auth_source" "$runtime_codex_home/auth.json" \
     || ! chmod 600 "$runtime_codex_home/auth.json"; then
    rm -f "$runtime_codex_home/auth.json"
    echo "Codexの認証情報を隔離された作業用コピーへ用意できませんでした" >&2
    return 1
  fi
  local agent_bin_dir="$repo_dir/scripts/agent-bin"
  echo "Codex実行モデル: $fallback_model" >&2
  # macOSはSeatbeltの入れ子を許さない。外側のSeatbeltだけで本体repoと
  # Git/SSH認証経路を隠し、書込みを今回の作業用コピーへ限定する。
  /usr/bin/sandbox-exec \
    -f "$CODEX_FALLBACK_LIB_DIR/agent-sandbox.sb" \
    -D "REPO_DIR=$original_repo_dir" \
    -D "HOME_DIR=$HOME" \
    -D "CODEX_AUTH_SOURCE=$auth_source" \
    -D "SCRATCH_BASE_DIR=$(dirname "$repo_dir")" \
    -D "SCRATCH_DIR=$repo_dir" \
    -D "SSH_AUTH_SOCKET=${SSH_AUTH_SOCK:-/private/tmp/ai-news-no-ssh-agent-socket}" \
    /usr/bin/env -u SSH_AUTH_SOCK -u GIT_ASKPASS -u GIT_SSH_COMMAND \
      -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CREDENTIAL_HELPER \
      -u NODE_OPTIONS \
      HOME="$runtime_home" CODEX_HOME="$runtime_codex_home" TMPDIR="$runtime_tmp" \
      PATH="$agent_bin_dir:$(dirname "$node_bin"):$PATH" REPO_DIR="$repo_dir" \
    "$codex_bin" exec --skip-git-repo-check --ignore-user-config --ephemeral \
    -m "$fallback_model" \
    -s danger-full-access \
    -c approval_policy=never \
    -c agents.enabled=false \
    -c apps._default.enabled=false \
    -c web_search=live \
    -c allow_login_shell=false \
    -c shell_environment_policy.inherit=none \
    -C "$repo_dir" \
    "$(cat "$prompt_file")"$'\n'"実行日: ${AI_NEWS_DATE:-$(date +%Y-%m-%d)}" 2>&1 | tee "$attempt_log"
  local status=${PIPESTATUS[0]}
  rm -f "$runtime_codex_home/auth.json"
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
  local agent_bin_dir="$repo_dir/scripts/agent-bin"
  /usr/bin/env -u SSH_AUTH_SOCK -u GIT_ASKPASS -u GIT_SSH_COMMAND \
    -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CREDENTIAL_HELPER \
    PATH="$agent_bin_dir:$(dirname "$node_bin"):$PATH" REPO_DIR="$repo_dir" \
    "$claude_bin" --restricted --strict-mcp-config --no-chrome \
      --tools Read,Write,Edit,WebSearch \
      --allowedTools Read,Write,Edit,WebSearch \
      --permission-mode acceptEdits --permission-prompts none \
      -p "$(cat "$prompt_file")"$'\n'"実行日: ${AI_NEWS_DATE:-$(date +%Y-%m-%d)}" 2>&1
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
