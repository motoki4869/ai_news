#!/bin/bash
# 日次ニュース更新でCodex CLIとClaude Codeを起動するための共通ヘルパー。
# investment・ai_news 両リポジトリに同一内容を複製配置している（意図的に非共有）。
# 呼び出し元スクリプトから `source` して使うこと。
CODEX_FALLBACK_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Codexが起動するコマンドの権限プロファイル（Codex本体の認証・モデル通信・Web検索には効かない）。
# 読めるのはシステムの最小限と作業用コピー(-C)だけで、本体repo・HOME・認証情報・/tmpは
# 読み書きできず、ネットワークも使えない。macOSはSeatbeltを入れ子にできないため、
# 外側からsandbox-execで包まず、この1層だけで境界を作る。
# 実CLIでの確認: test/test_codex_command_sandbox.sh（API不要）、test/test_real_codex_sandbox.sh
CODEX_COMMAND_PERMISSIONS=(
  -c 'default_permissions="ai_news_agent"'
  -c 'permissions={ai_news_agent={filesystem={":minimal"="read", ":slash_tmp"="deny", ":workspace_roots"={"."="write"}}, network={enabled=false}}}'
)

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

  # Codex本体は認証情報を読む必要があるが、Codexが起動するコマンドからは読ませない。
  # 認証用のCODEX_HOMEは作業用コピーの外（HOME配下）に作り、コマンド側は
  # CODEX_COMMAND_PERMISSIONSで作業用コピーとシステムの最小限しか読めないようにする。
  local auth_source="${CODEX_HOME:-$HOME/.codex}/auth.json"
  local runtime_base="${AI_NEWS_CODEX_RUNTIME_BASE:-$HOME/Library/Caches/ai-news-codex-runtime}"
  local runtime_dir runtime_home runtime_codex_home runtime_tmp stale_auth
  mkdir -p "$runtime_base" && chmod 700 "$runtime_base" || return 1
  # 前回が強制終了で認証のコピーを消せなかった場合に備えて掃除する。
  for stale_auth in "$runtime_base"/run.*/home/.codex/auth.json; do
    [ -f "$stale_auth" ] || continue
    rm -f "$stale_auth" || echo "前回の実行で残ったCodex認証情報のコピーを削除できませんでした: $stale_auth" >&2
  done
  runtime_dir="$(mktemp -d "$runtime_base/run.XXXXXX")" || return 1
  runtime_home="$runtime_dir/home"
  runtime_codex_home="$runtime_home/.codex"
  runtime_tmp="$repo_dir/.codex-tmp"
  mkdir -p "$runtime_codex_home" "$runtime_tmp" || return 1
  local attempt_log
  attempt_log=$(mktemp "${TMPDIR:-/tmp}/ai-news-codex-fallback.XXXXXX") || return 1
  cd "$repo_dir" || return 1
  if ! (umask 077 && cp "$auth_source" "$runtime_codex_home/auth.json"); then
    rm -f "$runtime_codex_home/auth.json"
    echo "Codexの認証情報を作業用コピーの外の一時領域へ用意できませんでした" >&2
    return 1
  fi
  local initial_auth_sum
  initial_auth_sum="$(cksum < "$runtime_codex_home/auth.json")"
  local agent_bin_dir="$repo_dir/scripts/agent-bin"
  echo "Codex実行モデル: $fallback_model" >&2
  /usr/bin/env -u SSH_AUTH_SOCK -u GIT_ASKPASS -u GIT_SSH_COMMAND \
      -u GIT_CONFIG_GLOBAL -u GIT_CONFIG_SYSTEM -u GIT_CREDENTIAL_HELPER \
      -u NODE_OPTIONS \
      HOME="$runtime_home" CODEX_HOME="$runtime_codex_home" TMPDIR="$runtime_tmp" \
      PATH="$agent_bin_dir:$(dirname "$node_bin"):$PATH" REPO_DIR="$repo_dir" \
    "$codex_bin" exec --skip-git-repo-check --ignore-user-config --ephemeral \
    -m "$fallback_model" \
    "${CODEX_COMMAND_PERMISSIONS[@]}" \
    -c approval_policy=never \
    -c agents.enabled=false \
    -c apps._default.enabled=false \
    -c web_search=live \
    -c allow_login_shell=false \
    -c shell_environment_policy.inherit=none \
    -C "$repo_dir" \
    "$(cat "$prompt_file")"$'\n'"実行日: ${AI_NEWS_DATE:-$(date +%Y-%m-%d)}" < /dev/null 2>&1 | tee "$attempt_log"
  local status=${PIPESTATUS[0]}
  # 実行中にこのCodexがトークンを更新した場合だけ元へ戻す。古いrefresh tokenのままだと
  # 通常のCodexがログアウト状態になることがある（元側だけが更新された場合は触らない）。
  if [ -s "$runtime_codex_home/auth.json" ] \
     && [ "$(cksum < "$runtime_codex_home/auth.json")" != "$initial_auth_sum" ] \
     && "${PYTHON_BIN:-/usr/bin/python3}" -c 'import json,sys; json.load(open(sys.argv[1]))' "$runtime_codex_home/auth.json" 2>/dev/null; then
    (umask 077 && cp "$runtime_codex_home/auth.json" "$auth_source.ai-news.$$" \
      && mv -f "$auth_source.ai-news.$$" "$auth_source") \
      || echo "更新されたCodex認証情報を元の場所へ戻せませんでした" >&2
  fi
  if ! rm -f "$runtime_codex_home/auth.json"; then
    echo "Codex認証情報の一時コピーを削除できませんでした: $runtime_codex_home/auth.json" >&2
    [ "$status" -ne 0 ] || status=1
  fi
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
