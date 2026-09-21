#!/bin/bash
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/ai-news-daily-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/fake-claude" <<'EOF'
#!/bin/sh
printf '%s\n' 'SUMMARY: ERROR: 用語集生成に失敗しました'
exit 0
EOF
chmod +x "$TMP_DIR/fake-claude"

cat > "$TMP_DIR/fake-claude-no-ok" <<'EOF'
#!/bin/sh
printf '%s\n' 'SUMMARY: 更新しました'
exit 0
EOF
chmod +x "$TMP_DIR/fake-claude-no-ok"

cat > "$TMP_DIR/osascript" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$FAKE_OSASCRIPT_LOG"
EOF
chmod +x "$TMP_DIR/osascript"

set +e
PATH="$TMP_DIR:$PATH" \
CLAUDE_BIN="$TMP_DIR/fake-claude" \
FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
NOTEBOOKLM_AUDIO_SCRIPT="$TMP_DIR/notebooklm-audio" \
GH_BIN="$TMP_DIR/gh" \
  "$REPO_DIR/scripts/daily_news.sh" > "$TMP_DIR/output.log" 2>&1
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  echo "SUMMARY: ERROR を終了コード0のまま成功扱いしました" >&2
  exit 1
fi

if ! grep -q 'daily_news.shが失敗しました' "$TMP_DIR/osascript.log"; then
  echo "失敗通知が送られていません" >&2
  cat "$TMP_DIR/output.log" >&2
  exit 1
fi

set +e
PATH="$TMP_DIR:$PATH" \
CLAUDE_BIN="$TMP_DIR/fake-claude-no-ok" \
FAKE_OSASCRIPT_LOG="$TMP_DIR/osascript.log" \
NOTEBOOKLM_AUDIO_SCRIPT="$TMP_DIR/notebooklm-audio" \
GH_BIN="$TMP_DIR/gh" \
  "$REPO_DIR/scripts/daily_news.sh" > "$TMP_DIR/output-no-ok.log" 2>&1
NO_OK_STATUS=$?
set -e

if [ "$NO_OK_STATUS" -eq 0 ]; then
  echo "SUMMARY: OK:がない更新を成功扱いしました" >&2
  exit 1
fi

echo "SUMMARY: daily_news.shがSUMMARY: ERROR:を失敗として扱いました"
