#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-news-daily-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_REPO="$TMP_DIR/repo"
TODAY="$(date +%Y-%m-%d)"
MONTH="$(date +%Y%m)"
TODAY_MONTH=$((10#${TODAY:5:2}))
TODAY_DAY=$((10#${TODAY:8:2}))
mkdir -p "$TEST_REPO/everyday_news" "$TEST_REPO/history" "$TEST_REPO/.claude"

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
case "$FAKE_CODEX_MODE" in
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
  error) printf '%s\n' 'SUMMARY: ERROR: 用語集生成に失敗しました'; exit 0 ;;
  no-ok) printf '%s\n' 'SUMMARY: 更新しました'; exit 0 ;;
  ok-exit1) printf '%s\n' 'SUMMARY: OK: 成功したように見える要約'; exit 1 ;;
  limit-zero) printf '%s\n' "ERROR: You've hit your usage limit. Visit https://chatgpt.com/codex/settings/usage"; exit 0 ;;
  fail) printf '%s\n' 'Codexが起動できませんでした'; exit 1 ;;
  *) printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$FAKE_LINE_MSG_FILE"; printf '%s\n' 'SUMMARY: OK: テスト更新'; exit 0 ;;
esac
EOF
chmod +x "$TMP_DIR/fake-codex"

cat > "$TMP_DIR/fake-claude-ok" <<'EOF'
#!/bin/sh
printf 'おはようございます☀️ %s月%s日、テストです。\n' "$TODAY_MONTH" "$TODAY_DAY" > "$FAKE_LINE_MSG_FILE"
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
exit 0
EOF
chmod +x "$TMP_DIR/fake-gh"

git -C "$TEST_REPO" init -q
git -C "$TEST_REPO" config user.email test@example.com
git -C "$TEST_REPO" config user.name test
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
git -C "$TEST_REPO" add "everyday_news/$MONTH.md"
git -C "$TEST_REPO" commit -q -m 'seed daily news'

run_daily() {
  local codex_mode="$1"
  local output_file="$2"
  local notify_state_dir="${4:-$TMP_DIR/notify-state}"
  set +e
  PATH="$TMP_DIR:$PATH" \
  REPO_DIR="$TEST_REPO" \
  CODEX_BIN="$TMP_DIR/fake-codex" \
  FAKE_CODEX_MODE="$codex_mode" \
  CLAUDE_BIN="${5:-$TMP_DIR/fake-claude-ok}" \
  FAKE_LINE_MSG_FILE="$TEST_REPO/everyday_news/line_message.txt" \
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

if ! grep -q '⚠️Claude Code経由' "$TMP_DIR/curl-body.log"; then
  echo "Claude Codeフォールバック成功時のLINE通知先頭に経由表示がありません" >&2
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
   || ! grep -q '必要数は5件' "$TMP_DIR/output-low-count.log"; then
  echo "5件未満の更新をcommit前または日次処理側で停止できませんでした" >&2
  cat "$TMP_DIR/output-low-count.log" >&2
  exit 1
fi
# commitフックを明示的に迂回したケースでも、push対象revisionをpre-pushが拒否する。
git -C "$TEST_REPO" -c core.hooksPath=/dev/null commit -q -m 'simulate bypassed commit hook'
bad_news_commit="$(git -C "$TEST_REPO" rev-parse HEAD)"
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
if (
  cd "$TEST_REPO"
  printf 'refs/heads/main %s refs/heads/main %040d\n' "$bad_news_commit" 0 \
    | AI_NEWS_MIN_ITEMS=5 \
      AI_NEWS_DATE="$TODAY" \
      AI_NEWS_VALIDATOR="$SCRIPT_ROOT/scripts/validate_daily_news.py" \
      AI_NEWS_PYTHON_BIN="$(command -v python3)" \
        "$SCRIPT_ROOT/scripts/git-hooks/pre-push"
) > "$TMP_DIR/output-low-count-pre-push.log" 2>&1; then
  echo "5件未満のニュースを含むcommitをpush前に止められませんでした" >&2
  exit 1
fi
if ! grep -q '必要数は5件' "$TMP_DIR/output-low-count-pre-push.log"; then
  echo "pre-pushフックが件数不足の理由を示しませんでした" >&2
  cat "$TMP_DIR/output-low-count-pre-push.log" >&2
  exit 1
fi
git -C "$TEST_REPO" reset --hard -q HEAD^

printf '%s\n' staged-change > "$TEST_REPO/unrelated.md"
git -C "$TEST_REPO" add unrelated.md

set +e
PATH="$TMP_DIR:$PATH" \
REPO_DIR="$TEST_REPO" \
CODEX_BIN="$TMP_DIR/fake-codex" \
FAKE_CODEX_MODE=no-ok \
CLAUDE_BIN="$TMP_DIR/fake-claude-ok" \
FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
FAKE_CURL_LOG="$TMP_DIR/curl.log" \
FAKE_CURL_BODY_LOG="$TMP_DIR/curl-body.log" \
  FAKE_AUDIO_LOG="$TMP_DIR/audio.log" \
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

# 作業ツリーに当日見出しがあっても、HEADにcommitされていなければLINE通知しない。
git -C "$TEST_REPO" reset -q unrelated.md
cat > "$TEST_REPO/everyday_news/$MONTH.md" <<EOF
# ${TODAY:0:4}年${TODAY:5:2}月 AIニュースまとめ
EOF
git -C "$TEST_REPO" add "everyday_news/$MONTH.md"
git -C "$TEST_REPO" commit -q -m 'remove current day from seed'
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

echo "SUMMARY: daily_news.shの失敗判定、同日LINE通知claim、commit済み音声再試行を確認しました"
