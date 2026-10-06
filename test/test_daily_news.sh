#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-news-daily-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT
mkdir -p "$TMP_DIR/codex-home"
printf '{}\n' > "$TMP_DIR/codex-home/auth.json"

TEST_REPO="$TMP_DIR/repo"
TODAY="$(date +%Y-%m-%d)"
MONTH="$(date +%Y%m)"
TODAY_MONTH=$((10#${TODAY:5:2}))
TODAY_DAY=$((10#${TODAY:8:2}))
mkdir -p "$TEST_REPO/everyday_news" "$TEST_REPO/history" "$TEST_REPO/.claude" \
  "$TEST_REPO/docs" "$TEST_REPO/scripts/agent-bin"
printf '# 用語集\n' > "$TEST_REPO/docs/glossary.md"
cp "$SCRIPT_ROOT/scripts/agent-bin/git" "$TEST_REPO/scripts/agent-bin/git"

cat > "$TMP_DIR/fake-codex" <<'EOF'
#!/bin/sh
if [ "$1" = app-server ]; then
  while IFS= read -r request; do
    case "$request" in
      *'"id": 2'*) printf '%s\n' '{"jsonrpc":"2.0","id":2,"result":{"data":[{"id":"test-model","isDefault":true}]}}' ;;
    esac
  done
  exit 0
fi
printf '%s|%s|%s\n' "$PWD" "$REPO_DIR" "${AI_NEWS_REAL_GIT:-}" >> "$REPO_DIR/agent-context.log"
case "$FAKE_CODEX_MODE" in
  wait-conflict)
    printf ready > "$REPO_DIR/conflict.ready"
    while [ ! -f "$REPO_DIR/conflict.done" ]; do sleep 0.05; done
    printf '# AIが編集した用語集\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'SUMMARY: OK: 競合検査テスト'
    exit 0
    ;;
  boundary-probe)
    # 本体repoへの境界はCodexのコマンド用サンドボックスが担う（実CLIでの確認は
    # test/test_codex_command_sandbox.sh）。ここでは起動条件と認証情報の置き場所を確認する。
    case " $* " in
      *' default_permissions="ai_news_agent" '*) ;;
      *) printf '%s\n' '権限プロファイルが指定されていません'; exit 1 ;;
    esac
    case " $* " in
      *danger-full-access*) printf '%s\n' 'sandboxが無効化されています'; exit 1 ;;
    esac
    case "$CODEX_HOME/" in
      "$REPO_DIR/"*) printf '%s\n' 'CODEX_HOMEが作業用コピー内にあります'; exit 1 ;;
    esac
    if [ -n "$(find "$REPO_DIR" -name auth.json -print -quit)" ]; then
      printf '%s\n' '作業用コピー内に認証情報があります'
      exit 1
    fi
    printf '%s\n' 'BOUNDARY: OK'
    printf '%s\n' 'SUMMARY: OK: 境界確認'
    exit 0
    ;;
  update-five)
    today="$(date +%Y-%m-%d)"
    month="$(date +%Y%m)"
    cat >> "$REPO_DIR/everyday_news/$month.md" <<NEWS

- **【産業】親スクリプトcommitテスト**（[出典](https://example.com/parent-commit)）
  日次スクリプトがモデル終了後にcommit・pushすることを確認します。
NEWS
    printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$REPO_DIR/everyday_news/line_message.txt"
    printf '%s\n' 'SUMMARY: OK: 6件目を追加しました'
    exit 0
    ;;
  check-untracked)
    if ! grep -q '未追跡の入力' "$REPO_DIR/everyday_news/202501.md"; then
      printf '%s\n' 'SUMMARY: ERROR: 未追跡Markdownが作業用コピーにありません'
      exit 1
    fi
    printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$REPO_DIR/everyday_news/line_message.txt"
    printf '%s\n' 'SUMMARY: OK: 未追跡Markdownを確認しました'
    exit 0
    ;;
  low-count)
    today="$(date +%Y-%m-%d)"
    month="$(date +%Y%m)"
    cat > "$REPO_DIR/everyday_news/$month.md" <<NEWS
# $month AIニュースまとめ

## $today

- **【技術】少数ニュース**（[出典](https://example.com/one)）
  1件だけのテストニュースです。
NEWS
    git add "everyday_news/$month.md"
    git commit -m 'should be blocked by minimum news count'
    printf '%s\n' 'SUMMARY: OK: 少数ニュース'
    exit 0
    ;;
  error-dirty)
    printf '# 失敗したAIの途中成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'SUMMARY: ERROR: 編集を完了できませんでした'
    exit 0
    ;;
  no-ok-dirty)
    printf '# 不完全なAIの途中成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'SUMMARYがありません'
    exit 0
    ;;
  trailing-dirty)
    printf '# 途中終了したAIの成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'SUMMARY: OK: 編集完了' 'ただし最終応答は未完了'
    exit 0
    ;;
  mixed-summary-dirty)
    printf '# エラーを含むAIの成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'SUMMARY: ERROR: 検査失敗' 'SUMMARY: OK: 編集完了'
    exit 0
    ;;
  invalid-dirty)
    printf '# 検査に失敗するAIの途中成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '# 壊れたニュース\n' > "$REPO_DIR/everyday_news/$(date +%Y%m).md"
    printf '%s\n' 'SUMMARY: OK: 編集完了'
    exit 0
    ;;
  fail-dirty)
    printf '# Codexの途中成果\n' > "$REPO_DIR/docs/glossary.md"
    printf '%s\n' 'Codexが途中で失敗しました'
    exit 1
    ;;
  error) printf '%s\n' 'SUMMARY: ERROR: 用語集生成に失敗しました'; exit 0 ;;
  no-ok) printf '%s\n' 'SUMMARY: 更新しました'; exit 0 ;;
  ok-exit1) printf '%s\n' 'SUMMARY: OK: 成功したように見える要約'; exit 1 ;;
  limit-zero) printf '%s\n' "ERROR: You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage"; exit 0 ;;
  fail) printf '%s\n' 'Codexが起動できませんでした'; exit 1 ;;
  *) printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$REPO_DIR/everyday_news/line_message.txt"; printf '%s\n' 'SUMMARY: OK: テスト更新'; exit 0 ;;
esac
EOF
chmod +x "$TMP_DIR/fake-codex"

cat > "$TMP_DIR/fake-claude-ok" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_CLAUDE_ARGS_LOG"
printf '%s|%s|%s\n' "$PWD" "$REPO_DIR" "${AI_NEWS_REAL_GIT:-}" >> "$REPO_DIR/agent-context.log"
printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$REPO_DIR/everyday_news/line_message.txt"
printf '%s\n' 'SUMMARY: OK: Claudeフォールバック更新'
exit 0
EOF
chmod +x "$TMP_DIR/fake-claude-ok"

cat > "$TMP_DIR/fake-claude-exit1" <<'EOF'
#!/bin/sh
printf '%s\n' 'SUMMARY: OK: 成功したように見える要約'
exit 1
EOF
chmod +x "$TMP_DIR/fake-claude-exit1"

cat > "$TMP_DIR/fake-claude-dirty" <<'EOF'
#!/bin/sh
printf '# Claudeの途中成果\n' > "$REPO_DIR/docs/glossary.md"
printf '%s\n' 'SUMMARY: OK: 未完了の成功表示'
exit 1
EOF
chmod +x "$TMP_DIR/fake-claude-dirty"

cat > "$TMP_DIR/osascript" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_OSASCRIPT_LOG"
EOF
chmod +x "$TMP_DIR/osascript"

cat > "$TMP_DIR/curl" <<'EOF'
#!/bin/sh
printf '%s\n' called >> "$FAKE_CURL_LOG"
previous=''
for argument in "$@"; do
  if [ "$previous" = '-d' ]; then
    printf '%s\n' "$argument" >> "$FAKE_CURL_BODY_LOG"
    break
  fi
  previous="$argument"
done
if [ "${FAKE_CURL_FAIL:-0}" = 1 ]; then
  exit 1
fi
exit 0
EOF
chmod +x "$TMP_DIR/curl"

cat > "$TMP_DIR/fake-audio" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >> "$FAKE_AUDIO_LOG"
exit 0
EOF
chmod +x "$TMP_DIR/fake-audio"

cat > "$TMP_DIR/fake-gh" <<'EOF'
#!/bin/sh
# 音声生成（fake-audio）が呼ばれた後だけ、リリースにアセットがある状態を再現する。
if [ "$1" = release ] && [ "$2" = view ] && [ -n "${FAKE_GH_ASSET:-}" ] \
   && [ -s "${FAKE_AUDIO_LOG:-/nonexistent}" ]; then
  printf '%s\n' "$FAKE_GH_ASSET"
fi
exit 0
EOF
chmod +x "$TMP_DIR/fake-gh"

git -C "$TEST_REPO" init -q -b main
git -C "$TEST_REPO" config user.email test@example.com
git -C "$TEST_REPO" config user.name test
git init --bare -q "$TMP_DIR/origin.git"
git -C "$TEST_REPO" remote add origin "$TMP_DIR/origin.git"
cat > "$TEST_REPO/everyday_news/$MONTH.md" <<EOF
# ${TODAY:0:4}年${TODAY:5:2}月 AIニュースまとめ

## $TODAY
EOF
for news_number in 1 2 3 4 5; do
  cat >> "$TEST_REPO/everyday_news/$MONTH.md" <<EOF

- **【技術】テストニュース$news_number**（[出典](https://example.com/$news_number)）
  テスト用の当日ニュースです。
EOF
done
git -C "$TEST_REPO" add "everyday_news/$MONTH.md" docs/glossary.md scripts/agent-bin/git
git -C "$TEST_REPO" commit -q -m 'seed daily news'
git -C "$TEST_REPO" push -q -u origin main

run_daily() {
  local codex_mode="$1"
  local output_file="$2"
  local notify_state_dir="${4:-$TMP_DIR/notify-state}"
  set +e
  PATH="$TMP_DIR:$PATH" \
  REPO_DIR="$TEST_REPO" \
  CODEX_BIN="$TMP_DIR/fake-codex" \
  CODEX_HOME="$TMP_DIR/codex-home" \
  AI_NEWS_CODEX_RUNTIME_BASE="$TMP_DIR/codex-runtime" \
  FAKE_CODEX_MODE="$codex_mode" \
  CLAUDE_BIN="${5:-$TMP_DIR/fake-claude-ok}" \
  AI_NEWS_AGENT_WORKSPACE="$TMP_DIR/agent-workspace" \
  FAKE_CLAUDE_ARGS_LOG="$TMP_DIR/claude-args.log" \
  FAKE_REAL_REPO="$TEST_REPO" \
  TODAY_MONTH="$TODAY_MONTH" \
  TODAY_DAY="$TODAY_DAY" \
  FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
  FAKE_CURL_LOG="$TMP_DIR/curl.log" \
  FAKE_CURL_BODY_LOG="$TMP_DIR/curl-body.log" \
  FAKE_CURL_FAIL="${3:-0}" \
  LINE_CHANNEL_ACCESS_TOKEN=test-token \
  LINE_NOTIFY_DATE="$TODAY" \
  LINE_NOTIFY_STATE_DIR="$notify_state_dir" \
  NOTEBOOKLM_AUDIO_SCRIPT="$TMP_DIR/missing-audio" \
  GH_BIN="$TMP_DIR/missing-gh" \
    "$SCRIPT_ROOT/scripts/daily_news.sh" > "$output_file" 2>&1
  RUN_STATUS=$?
  set -e
  find "$TMP_DIR/agent-workspace" -name agent-context.log -type f -exec cat {} + \
    > "$TMP_DIR/agent-context.log"
  return "$RUN_STATUS"
}

if run_daily error "$TMP_DIR/output-error.log"; then
  echo "SUMMARY: ERROR を終了コード0のまま成功扱いしました" >&2
  exit 1
fi

if ! grep -q 'daily_news.shが失敗しました' "$TMP_DIR/osascript.log"; then
  echo "失敗通知が送られていません" >&2
  cat "$TMP_DIR/output-error.log" >&2
  exit 1
fi

if ! grep -q '用語集生成に失敗しました' "$TMP_DIR/osascript.log"; then
  echo "SUMMARY: ERRORの原因が失敗通知に含まれていません" >&2
  cat "$TMP_DIR/osascript.log" >&2
  cat "$TMP_DIR/output-error.log" >&2
  exit 1
fi

if run_daily no-ok "$TMP_DIR/output-no-ok.log"; then
  echo "SUMMARY: OK:がない更新を成功扱いしました" >&2
  exit 1
fi

if run_daily ok-exit1 "$TMP_DIR/output-ok-exit1.log" 0 "$TMP_DIR/notify-state-exit1" "$TMP_DIR/fake-claude-exit1"; then
  echo "終了コード1の実行を成功扱いしました" >&2
  exit 1
fi
if ! grep -q 'Codexに続きClaude Codeでの更新も失敗しました' "$TMP_DIR/osascript.log"; then
  echo "失敗通知に成功要約を原因として表示しました" >&2
  exit 1
fi

if run_daily ok "$TMP_DIR/output-ok-1.log" 1; then
  :
else
  echo "正常Summaryの実行を失敗扱いしました" >&2
  cat "$TMP_DIR/output-ok-1.log" >&2
  exit 1
fi

if run_daily ok "$TMP_DIR/output-ok-2.log" 0; then
  :
else
  echo "LINE通知失敗後の同日再送を失敗扱いしました" >&2
  exit 1
fi

if run_daily fail "$TMP_DIR/output-fallback.log" 0 "$TMP_DIR/notify-state-fallback"; then
  :
else
  echo "Codex失敗後のClaude Codeフォールバックを成功扱いしませんでした" >&2
  cat "$TMP_DIR/output-fallback.log" >&2
  exit 1
fi
if ! grep -q 'SUMMARY: OK: Claudeフォールバック更新' "$TMP_DIR/output-fallback.log"; then
  echo "Codex失敗後にClaude Codeへ切り替わりませんでした" >&2
  cat "$TMP_DIR/output-fallback.log" >&2
  exit 1
fi
if ! grep -q -- '--restricted --strict-mcp-config --no-chrome --tools Read,Write,Edit,WebSearch' "$TMP_DIR/claude-args.log" \
   || grep -q 'Bash' "$TMP_DIR/claude-args.log"; then
  echo "Claude Codeに制限外のコマンド実行ツールを渡しました" >&2
  cat "$TMP_DIR/claude-args.log" >&2
  exit 1
fi

if run_daily limit-zero "$TMP_DIR/output-limit-fallback.log" 0 "$TMP_DIR/notify-state-limit-fallback"; then
  :
else
  echo "終了コード0でもCodex利用上限メッセージを検出してClaude Codeへ切り替わりませんでした" >&2
  cat "$TMP_DIR/output-limit-fallback.log" >&2
  exit 1
fi
if ! grep -q '利用上限を示すメッセージを検出' "$TMP_DIR/output-limit-fallback.log" \
   || ! grep -q 'SUMMARY: OK: Claudeフォールバック更新' "$TMP_DIR/output-limit-fallback.log"; then
  echo "Codex利用上限を検出したフォールバック結果が不正です" >&2
  cat "$TMP_DIR/output-limit-fallback.log" >&2
  exit 1
fi

if [ ! -f "$TMP_DIR/curl.log" ] || [ "$(wc -l < "$TMP_DIR/curl.log")" -ne 7 ]; then
  echo "同日再実行でLINE通知を重複送信したか、初回通知を送信できませんでした" >&2
  cat "$TMP_DIR/curl.log" >&2
  exit 1
fi

glossary_before="$(cat "$TEST_REPO/docs/glossary.md")"
news_before="$(git -C "$TEST_REPO" hash-object "everyday_news/$MONTH.md")"
for mode in error-dirty no-ok-dirty trailing-dirty mixed-summary-dirty invalid-dirty; do
  if run_daily "$mode" "$TMP_DIR/output-$mode.log" 0 "$TMP_DIR/notify-state-$mode"; then
    echo "失敗したAIの成果物を成功扱いしました: $mode" >&2
    exit 1
  fi
  if [ "$(cat "$TEST_REPO/docs/glossary.md")" != "$glossary_before" ] \
     || [ "$(git -C "$TEST_REPO" hash-object "everyday_news/$MONTH.md")" != "$news_before" ]; then
    echo "失敗または未検査のAI成果物が本体repoへ同期されました: $mode" >&2
    exit 1
  fi
done

if ! run_daily fail-dirty "$TMP_DIR/output-fail-dirty.log" 0 "$TMP_DIR/notify-state-fail-dirty"; then
  echo "Codexの途中失敗後にClaude Codeへ正常に切り替わりませんでした" >&2
  cat "$TMP_DIR/output-fail-dirty.log" >&2
  exit 1
fi
if [ "$(cat "$TEST_REPO/docs/glossary.md")" != "$glossary_before" ] \
   || ! grep -q 'SUMMARY: OK: Claudeフォールバック更新' "$TMP_DIR/output-fail-dirty.log"; then
  echo "Codexの途中成果がClaude Codeの成果物に混入しました" >&2
  exit 1
fi

if run_daily fail-dirty "$TMP_DIR/output-fallback-dirty.log" 0 \
   "$TMP_DIR/notify-state-fallback-dirty" "$TMP_DIR/fake-claude-dirty"; then
  echo "失敗したClaude Codeの途中成果を成功扱いしました" >&2
  exit 1
fi
if [ "$(cat "$TEST_REPO/docs/glossary.md")" != "$glossary_before" ]; then
  echo "失敗したClaude Codeの途中成果が本体repoへ同期されました" >&2
  exit 1
fi

printf '\nstaged user edit\n' >> "$TEST_REPO/everyday_news/$MONTH.md"
git -C "$TEST_REPO" add "everyday_news/$MONTH.md"
context_before="$(wc -l < "$TMP_DIR/agent-context.log")"
workspaces_before="$(find "$TMP_DIR/agent-workspace" -mindepth 1 -maxdepth 1 -type d | wc -l)"
if run_daily update-five "$TMP_DIR/output-staged-target.log" 0 "$TMP_DIR/notify-state-staged-target"; then
  echo "更新対象にstaged変更があるのにAI作業を開始しました" >&2
  exit 1
fi
if [ "$(wc -l < "$TMP_DIR/agent-context.log")" -ne "$context_before" ] \
   || [ "$(find "$TMP_DIR/agent-workspace" -mindepth 1 -maxdepth 1 -type d | wc -l)" -ne "$workspaces_before" ] \
   || ! git -C "$TEST_REPO" diff --cached --name-only | grep -qx "everyday_news/$MONTH.md"; then
  echo "staged変更の事前検査がコピー準備・AI実行より後に行われました" >&2
  cat "$TMP_DIR/output-staged-target.log" >&2
  exit 1
fi
git -C "$TEST_REPO" restore --staged --worktree -- "everyday_news/$MONTH.md"

printf '\nunstaged user edit\n' >> "$TEST_REPO/docs/glossary.md"
context_before="$(wc -l < "$TMP_DIR/agent-context.log")"
workspaces_before="$(find "$TMP_DIR/agent-workspace" -mindepth 1 -maxdepth 1 -type d | wc -l)"
if run_daily update-five "$TMP_DIR/output-unstaged-target.log" 0 "$TMP_DIR/notify-state-unstaged-target"; then
  echo "更新対象にunstaged変更があるのにAI作業を開始しました" >&2
  exit 1
fi
if [ "$(wc -l < "$TMP_DIR/agent-context.log")" -ne "$context_before" ] \
   || [ "$(find "$TMP_DIR/agent-workspace" -mindepth 1 -maxdepth 1 -type d | wc -l)" -ne "$workspaces_before" ] \
   || ! tail -1 "$TMP_DIR/osascript.log" | grep -q '既存のunstaged変更'; then
  echo "unstaged変更の事前検査がAI作業より後に行われました" >&2
  cat "$TMP_DIR/output-unstaged-target.log" >&2
  exit 1
fi
git -C "$TEST_REPO" restore --worktree -- docs/glossary.md

(
  while [ -z "$(find "$TMP_DIR/agent-workspace" -name conflict.ready -print -quit)" ]; do sleep 0.05; done
  conflict_ready="$(find "$TMP_DIR/agent-workspace" -name conflict.ready -print -quit)"
  printf '# 実行中のユーザー編集\n' > "$TEST_REPO/docs/glossary.md"
  printf done > "${conflict_ready%.ready}.done"
) &
conflict_watcher=$!
if run_daily wait-conflict "$TMP_DIR/output-sync-conflict.log" 0 "$TMP_DIR/notify-state-sync-conflict"; then
  echo "実行中に更新された本体ファイルを上書きしました" >&2
  exit 1
fi
wait "$conflict_watcher"
if [ "$(cat "$TEST_REPO/docs/glossary.md")" != '# 実行中のユーザー編集' ] \
   || ! grep -q '実行開始後に更新対象' "$TMP_DIR/output-sync-conflict.log"; then
  echo "同期直前の競合検査が外部変更を保持しませんでした" >&2
  cat "$TMP_DIR/output-sync-conflict.log" >&2
  exit 1
fi
git -C "$TEST_REPO" restore --worktree -- docs/glossary.md

cat > "$TEST_REPO/everyday_news/202501.md" <<'NEWS'
# 2025年01月 AIニュースまとめ

## 2025-01-01

- **【技術】未追跡の入力**（[出典](https://example.com/untracked)）
  作業用コピーへの入力です。
NEWS
if ! run_daily check-untracked "$TMP_DIR/output-untracked.log" 0 "$TMP_DIR/notify-state-untracked"; then
  echo "未追跡MarkdownをAI作業用コピーに渡せませんでした" >&2
  cat "$TMP_DIR/output-untracked.log" >&2
  exit 1
fi

if ! run_daily boundary-probe "$TMP_DIR/output-boundary.log" 0 "$TMP_DIR/notify-state-boundary"; then
  echo "本体repoへの絶対パスアクセス境界を確認できませんでした" >&2
  cat "$TMP_DIR/output-boundary.log" >&2
  exit 1
fi
if ! grep -q 'BOUNDARY: OK' "$TMP_DIR/output-boundary.log"; then
  echo "本体repoへのアクセス拒否を確認できませんでした" >&2
  exit 1
fi

before_parent_commit="$(git -C "$TEST_REPO" rev-list --count HEAD)"
printf 'user staged change\n' > "$TEST_REPO/unrelated.md"
git -C "$TEST_REPO" add unrelated.md
if ! run_daily update-five "$TMP_DIR/output-parent-commit.log" 0 "$TMP_DIR/notify-state-parent-commit"; then
  echo "日次スクリプトによるcommit・pushを成功扱いしませんでした" >&2
  cat "$TMP_DIR/output-parent-commit.log" >&2
  exit 1
fi
after_parent_commit="$(git -C "$TEST_REPO" rev-list --count HEAD)"
remote_head="$(git --git-dir="$TMP_DIR/origin.git" rev-parse refs/heads/main)"
if [ "$after_parent_commit" -ne "$((before_parent_commit + 1))" ] \
   || [ "$remote_head" != "$(git -C "$TEST_REPO" rev-parse HEAD)" ]; then
  echo "日次スクリプトが対象ファイルをcommit・pushしませんでした" >&2
  cat "$TMP_DIR/output-parent-commit.log" >&2
  exit 1
fi
if [ "$(git -C "$TEST_REPO" diff --cached --name-only)" != "unrelated.md" ] \
   || ! git -C "$TEST_REPO" diff --quiet HEAD -- "everyday_news/$MONTH.md"; then
  echo "日次commitが通常Gitインデックスの無関係なstaged変更を壊しました" >&2
  git -C "$TEST_REPO" status --short >&2
  exit 1
fi
if [ ! -s "$TMP_DIR/agent-context.log" ] \
   || grep -q "|$TEST_REPO|" "$TMP_DIR/agent-context.log" \
   || grep -q '/.git' "$TMP_DIR/agent-context.log" \
   || grep -q 'AI_NEWS_REAL_GIT' "$TMP_DIR/agent-context.log"; then
  echo "AIプロセスに本体リポジトリまたは実git経路を渡しました" >&2
  cat "$TMP_DIR/agent-context.log" >&2
  exit 1
fi

if ! grep -q '⚠️Claude Code経由' "$TMP_DIR/curl-body.log"; then
  echo "Claude Codeフォールバック成功時のLINE通知先頭に経由表示がありません" >&2
  cat "$TMP_DIR/curl-body.log" >&2
  exit 1
fi

if run_daily fail "$TMP_DIR/output-fallback-line-retry.log" 1 "$TMP_DIR/notify-state-fallback-line-retry"; then
  :
else
  echo "LINE通知だけが失敗したClaude Codeフォールバックを更新失敗扱いしました" >&2
  exit 1
fi
if [ "$(cut -f2 "$TEST_REPO/logs/daily_news_source.txt")" != claude ]; then
  echo "Claude Code成功時の経由マーカーが保存されませんでした" >&2
  exit 1
fi
if run_daily ok "$TMP_DIR/output-codex-line-retry.log" 0 "$TMP_DIR/notify-state-fallback-line-retry"; then
  :
else
  echo "Claude Code経由のLINE再送テストでCodexの再実行に失敗しました" >&2
  exit 1
fi
if [ "$(cut -f2 "$TEST_REPO/logs/daily_news_source.txt")" != codex ] \
   || tail -1 "$TMP_DIR/curl-body.log" | grep -q '⚠️Claude Code経由'; then
  echo "後続のCodex成功時に古いClaude経由表示が残りました" >&2
  cat "$TMP_DIR/curl-body.log" >&2
  exit 1
fi

before_commit_count="$(git -C "$TEST_REPO" rev-list --count HEAD)"
if run_daily low-count "$TMP_DIR/output-low-count.log" 0 "$TMP_DIR/notify-state-low-count"; then
  echo "1件だけの日次更新を成功扱いしました" >&2
  exit 1
fi
after_commit_count="$(git -C "$TEST_REPO" rev-list --count HEAD)"
if [ "$before_commit_count" -ne "$after_commit_count" ] \
   || ! grep -q 'commit・pushを中止' "$TMP_DIR/output-low-count.log" \
   || ! grep -q 'AIエージェントからのcommit・pushは禁止' "$TMP_DIR/output-low-count.log" \
   || ! grep -q '必要数は5件' "$TMP_DIR/output-low-count.log"; then
  echo "5件未満の更新をcommit前または日次処理側で停止できませんでした" >&2
  cat "$TMP_DIR/output-low-count.log" >&2
  exit 1
fi
# commitフックを明示的に迂回したケースでも、push対象revisionをpre-pushが拒否する。
HOOK_TEST_REPO="$TMP_DIR/pre-push-test"
git clone -q "$TEST_REPO" "$HOOK_TEST_REPO"
git -C "$HOOK_TEST_REPO" config user.email test@example.com
git -C "$HOOK_TEST_REPO" config user.name test
cat > "$HOOK_TEST_REPO/everyday_news/$MONTH.md" <<EOF
# ${TODAY:0:4}年${TODAY:5:2}月 AIニュースまとめ

## $TODAY
EOF
for news_number in 1; do
  cat >> "$HOOK_TEST_REPO/everyday_news/$MONTH.md" <<EOF

- **【技術】テストニュース$news_number**（[出典](https://example.com/$news_number)）
  テスト用の当日ニュースです。
EOF
done
git -C "$HOOK_TEST_REPO" add "everyday_news/$MONTH.md"
git -C "$HOOK_TEST_REPO" -c core.hooksPath=/dev/null commit -q -m 'simulate bypassed commit hook'
bad_news_commit="$(git -C "$HOOK_TEST_REPO" rev-parse HEAD)"
if (
  cd "$HOOK_TEST_REPO"
  printf 'refs/heads/main %s refs/heads/main %040d\n' "$bad_news_commit" 0 \
    | AI_NEWS_MIN_ITEMS=5 \
      AI_NEWS_DATE="$TODAY" \
      AI_NEWS_VALIDATOR="$SCRIPT_ROOT/scripts/validate_daily_news.py" \
      AI_NEWS_PYTHON_BIN="$(command -v python3)" \
        "$SCRIPT_ROOT/scripts/git-hooks/pre-push"
) > "$TMP_DIR/output-low-count-pre-push.log" 2>&1; then
  echo "5件未満のニュースを含むcommitをpush前に止められませんでした" >&2
  cat "$TMP_DIR/output-low-count-pre-push.log" >&2
  exit 1
fi
if ! grep -q '必要数は5件' "$TMP_DIR/output-low-count-pre-push.log"; then
  echo "pre-pushフックが件数不足の理由を示しませんでした" >&2
  cat "$TMP_DIR/output-low-count-pre-push.log" >&2
  exit 1
fi

printf '%s\n' staged-change > "$TEST_REPO/unrelated.md"
git -C "$TEST_REPO" add unrelated.md

set +e
PATH="$TMP_DIR:$PATH" \
REPO_DIR="$TEST_REPO" \
CODEX_BIN="$TMP_DIR/fake-codex" \
CODEX_HOME="$TMP_DIR/codex-home" \
AI_NEWS_CODEX_RUNTIME_BASE="$TMP_DIR/codex-runtime" \
FAKE_CODEX_MODE=no-ok \
CLAUDE_BIN="$TMP_DIR/fake-claude-ok" \
FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
FAKE_CURL_LOG="$TMP_DIR/curl.log" \
FAKE_CURL_BODY_LOG="$TMP_DIR/curl-body.log" \
  FAKE_GH_ASSET="$TODAY.m4a" \
  FAKE_AUDIO_LOG="$TMP_DIR/audio.log" \
  GIT_TRACE2_EVENT="$TMP_DIR/audio-git-trace.json" \
  LINE_NOTIFY_DATE="$TODAY" \
LINE_NOTIFY_STATE_DIR="$TMP_DIR/notify-state-audio" \
NOTEBOOKLM_AUDIO_SCRIPT="$TMP_DIR/fake-audio" \
GH_BIN="$TMP_DIR/fake-gh" \
  "$SCRIPT_ROOT/scripts/daily_news.sh" > "$TMP_DIR/output-audio.log" 2>&1
AUDIO_STATUS=$?
set -e

if [ "$AUDIO_STATUS" -eq 0 ] || ! grep -qx "$TODAY" "$TMP_DIR/audio.log"; then
  echo "当日分がcommit済みなのにSummary失敗時の音声再試行が行われませんでした" >&2
  cat "$TMP_DIR/output-audio.log" >&2
  exit 1
fi

if ! git -C "$TEST_REPO" diff --cached --name-only | grep -qx 'unrelated.md'; then
  echo "音声リトライが無関係なstaged変更を保持していません" >&2
  exit 1
fi
if git -C "$TEST_REPO" show --format= --name-only HEAD | grep -qx 'unrelated.md'; then
  echo "音声リトライが無関係な変更をcommitしました" >&2
  exit 1
fi
if ! git -C "$TEST_REPO" show --format= --name-only HEAD | grep -qx 'history/audio-data.js' \
   || ! grep -q 'pre-push' "$TMP_DIR/audio-git-trace.json" \
   || [ "$(git --git-dir="$TMP_DIR/origin.git" rev-parse refs/heads/main)" != "$(git -C "$TEST_REPO" rev-parse HEAD)" ]; then
  echo "音声リトライのcommit・pushで最低5件のpre-pushフックが実行されませんでした" >&2
  cat "$TMP_DIR/output-audio.log" >&2
  exit 1
fi

# 作業ツリーに当日見出しがあっても、HEADにcommitされていなければLINE通知しない。
git -C "$TEST_REPO" reset -q unrelated.md
cat > "$TEST_REPO/everyday_news/$MONTH.md" <<EOF
# ${TODAY:0:4}年${TODAY:5:2}月 AIニュースまとめ
EOF
git -C "$TEST_REPO" add "everyday_news/$MONTH.md"
git -C "$TEST_REPO" commit -q -m 'remove current day from seed'
git -C "$TEST_REPO" push -q origin main
cat >> "$TEST_REPO/everyday_news/$MONTH.md" <<EOF

## $TODAY

- **【技術】未commitテスト**（[出典](https://example.com)）
  作業ツリーだけに存在する当日ニュースです。
EOF

before_curl_count="$(wc -l < "$TMP_DIR/curl.log" | tr -d ' ')"
if run_daily ok "$TMP_DIR/output-uncommitted.log" 0 "$TMP_DIR/notify-state-uncommitted"; then
  echo "未commit当日分を成功扱いしました" >&2
  exit 1
fi
after_curl_count="$(wc -l < "$TMP_DIR/curl.log" | tr -d ' ')"
if [ "$after_curl_count" -ne "$((before_curl_count + 1))" ]; then
  echo "未commit当日分の失敗理由をLINE通知しませんでした" >&2
  exit 1
fi

git -C "$TEST_REPO" checkout -q -- "everyday_news/$MONTH.md"

# 日次処理以外の未push commitがあれば、AI作業もpushも行わない。
printf 'user work\n' > "$TEST_REPO/user-work.md"
git -C "$TEST_REPO" add user-work.md
git -C "$TEST_REPO" commit -q -m 'user work in progress'
remote_before="$(git --git-dir="$TMP_DIR/origin.git" rev-parse refs/heads/main)"
context_before="$(wc -l < "$TMP_DIR/agent-context.log")"
if run_daily update-five "$TMP_DIR/output-unpushed.log" 0 "$TMP_DIR/notify-state-unpushed"; then
  echo "未pushのユーザーcommitがあるのに日次更新を成功扱いしました" >&2
  exit 1
fi
if [ "$(git --git-dir="$TMP_DIR/origin.git" rev-parse refs/heads/main)" != "$remote_before" ] \
   || [ "$(wc -l < "$TMP_DIR/agent-context.log")" -ne "$context_before" ] \
   || ! tail -1 "$TMP_DIR/osascript.log" | grep -q '未pushのcommit'; then
  echo "未pushのユーザーcommitを検出する前にAI作業またはpushが行われました" >&2
  cat "$TMP_DIR/output-unpushed.log" >&2
  exit 1
fi
git -C "$TEST_REPO" push -q origin main

# 音声一覧ファイルにユーザーの未commit編集があれば、音声処理で上書き・commitしない。
# 音声処理に進むよう、当日分5件をcommit済みにしておく。
git -C "$TEST_REPO" show "$(git -C "$TEST_REPO" rev-parse ":/remove current day from seed")~1:everyday_news/$MONTH.md" > "$TEST_REPO/everyday_news/$MONTH.md"
grep -q "^## $TODAY$" "$TEST_REPO/everyday_news/$MONTH.md"
git -C "$TEST_REPO" add "everyday_news/$MONTH.md"
git -C "$TEST_REPO" commit -q -m "$TODAY のAIニュースを更新"
git -C "$TEST_REPO" push -q origin main
mkdir -p "$TEST_REPO/history"
git -C "$TEST_REPO" show HEAD:history/audio-data.js > "$TEST_REPO/history/audio-data.js"
printf '// user edit\n' >> "$TEST_REPO/history/audio-data.js"
audio_head_before="$(git -C "$TEST_REPO" rev-parse HEAD)"
: > "$TMP_DIR/audio-dirty.log"
set +e
PATH="$TMP_DIR:$PATH" \
REPO_DIR="$TEST_REPO" \
CODEX_BIN="$TMP_DIR/fake-codex" \
CODEX_HOME="$TMP_DIR/codex-home" \
AI_NEWS_CODEX_RUNTIME_BASE="$TMP_DIR/codex-runtime" \
FAKE_CODEX_MODE=no-ok \
CLAUDE_BIN="$TMP_DIR/fake-claude-ok" \
FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
FAKE_CURL_LOG="$TMP_DIR/curl.log" \
FAKE_CURL_BODY_LOG="$TMP_DIR/curl-body.log" \
FAKE_GH_ASSET="$TODAY.m4a" \
FAKE_AUDIO_LOG="$TMP_DIR/audio-dirty.log" \
LINE_NOTIFY_DATE="$TODAY" \
LINE_NOTIFY_STATE_DIR="$TMP_DIR/notify-state-audio-dirty" \
NOTEBOOKLM_AUDIO_SCRIPT="$TMP_DIR/fake-audio" \
GH_BIN="$TMP_DIR/fake-gh" \
  "$SCRIPT_ROOT/scripts/daily_news.sh" > "$TMP_DIR/output-audio-dirty.log" 2>&1
set -e
if [ -s "$TMP_DIR/audio-dirty.log" ] \
   || [ "$(git -C "$TEST_REPO" rev-parse HEAD)" != "$audio_head_before" ] \
   || [ "$(tail -1 "$TEST_REPO/history/audio-data.js")" != '// user edit' ] \
   || ! grep -q '音声一覧ファイルに未commitの変更がある' "$TMP_DIR/output-audio-dirty.log"; then
  echo "音声一覧ファイルの未commit編集を上書きまたはcommitしました" >&2
  cat "$TMP_DIR/output-audio-dirty.log" >&2
  exit 1
fi

echo "SUMMARY: daily_news.shの失敗判定、同日LINE通知claim、commit済み音声再試行、未push commitと音声一覧の保護を確認しました"
