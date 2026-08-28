#!/usr/bin/env bash
set -uo pipefail

REPO_DIR=$(cd "$(dirname "$0")/.." && pwd)
AUDIO_DATA_SCRIPT="$REPO_DIR/scripts/generate_audio_data.py"
CONFIG_FILE="${NOTEBOOKLM_AUDIO_ENV:-$REPO_DIR/scripts/notebooklm_audio.env}"
TARGET_DATE="${1:-$(date +%F)}"
SOURCE_TITLE="AIニュース日次: $TARGET_DATE"
AUDIO_DIR="$REPO_DIR/history/audio"
AUDIO_FILE="$AUDIO_DIR/$TARGET_DATE.m4a"

log() {
  printf '[notebooklm-audio] %s\n' "$*"
}

skip() {
  log "スキップ: $*"
  exit 0
}

fail() {
  log "警告: $*" >&2
  exit 0
}

if [[ ! -f "$CONFIG_FILE" ]]; then
  fail "設定ファイルがありません: $CONFIG_FILE"
fi

# shellcheck disable=SC1090
source "$CONFIG_FILE"
NLM_BIN="${NLM_BIN:-$HOME/.local/bin/nlm}"
AUDIO_MAX_WAIT_SECONDS="${AUDIO_MAX_WAIT_SECONDS:-1200}"
AUDIO_POLL_SECONDS="${AUDIO_POLL_SECONDS:-15}"

if [[ -z "${NOTEBOOKLM_NOTEBOOK_ID:-}" ]]; then
  fail "NOTEBOOKLM_NOTEBOOK_ID が設定されていません"
fi
if [[ ! -x "$NLM_BIN" ]]; then
  fail "nlm CLIが実行できません: $NLM_BIN"
fi
if [[ -s "$AUDIO_FILE" ]]; then
  skip "音声ファイルが既に存在します: $AUDIO_FILE"
fi

SOURCE_FILE="$REPO_DIR/everyday_news/${TARGET_DATE:0:4}${TARGET_DATE:5:2}.md"
if [[ ! -f "$SOURCE_FILE" ]]; then
  fail "当日のニュースファイルがありません: $SOURCE_FILE"
fi

SOURCE_TMP=$(mktemp "${TMPDIR:-/tmp}/ai-news-audio-source.XXXXXX.md")
DOWNLOAD_TMP=$(mktemp "${TMPDIR:-/tmp}/ai-news-audio-download.XXXXXX.m4a")
trap 'rm -f "$SOURCE_TMP" "$DOWNLOAD_TMP"' EXIT

if ! python3 "$AUDIO_DATA_SCRIPT" \
  --extract-date "$TARGET_DATE" \
  --source-file "$SOURCE_FILE" \
  --output "$SOURCE_TMP"; then
  fail "当日ニュースセクションを抽出できませんでした"
fi

if ! "$NLM_BIN" login --check >/dev/null 2>&1; then
  fail "NotebookLMのログイン状態を確認できませんでした"
fi

extract_ids() {
  python3 -c '
import json, sys
try:
    value = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
items = value if isinstance(value, list) else value.get("sources", []) if isinstance(value, dict) else []
for item in items:
    if isinstance(item, dict):
        value = item.get("id") or item.get("source_id")
        if value:
            print(value)
'
}

extract_matching_source_id() {
  python3 -c '
import json
import sys
try:
    payload = json.loads(sys.argv[1])
except Exception:
    raise SystemExit(0)
title = sys.argv[2]
items = payload if isinstance(payload, list) else payload.get("sources", []) if isinstance(payload, dict) else []
matches = []
for item in items:
    if not isinstance(item, dict):
        continue
    if item.get("title") == title:
        source_id = item.get("id") or item.get("source_id")
        if source_id:
            matches.append(source_id)
if matches:
    print(matches[-1])
' "$1" "$SOURCE_TITLE"
}

SOURCE_ADD_OUTPUT=$("$NLM_BIN" source add "$NOTEBOOKLM_NOTEBOOK_ID" \
  --file "$SOURCE_TMP" \
  --title "$SOURCE_TITLE" \
  --wait \
  --wait-timeout "$AUDIO_MAX_WAIT_SECONDS" 2>&1) || fail "当日ソースを追加できませんでした: $SOURCE_ADD_OUTPUT"

SOURCE_LIST=$("$NLM_BIN" list sources "$NOTEBOOKLM_NOTEBOOK_ID" --json 2>/dev/null) || fail "NotebookLMのソース一覧を取得できませんでした"
SOURCE_ID=$(extract_matching_source_id "$SOURCE_LIST")
if [[ -z "$SOURCE_ID" ]]; then
  fail "追加した当日ソースのIDを特定できませんでした"
fi

ARTIFACTS_BEFORE=$("$NLM_BIN" list artifacts "$NOTEBOOKLM_NOTEBOOK_ID" --json 2>/dev/null || true)
BEFORE_IDS=$(printf '%s' "$ARTIFACTS_BEFORE" | extract_ids)

CREATE_OUTPUT=$("$NLM_BIN" create audio "$NOTEBOOKLM_NOTEBOOK_ID" \
  --format deep_dive \
  --length default \
  --language ja \
  --source-ids "$SOURCE_ID" \
  --confirm 2>&1) || fail "NotebookLM音声の生成を開始できませんでした: $CREATE_OUTPUT"
log "音声生成を開始しました: $SOURCE_TITLE"

extract_new_audio_id() {
  python3 -c '
import json
import sys
before = set(filter(None, sys.argv[1].splitlines()))
try:
    payload = json.loads(sys.argv[2])
except Exception:
    raise SystemExit(0)
items = payload if isinstance(payload, list) else payload.get("artifacts", []) if isinstance(payload, dict) else []
candidates = []
for item in items:
    if not isinstance(item, dict):
        continue
    kind = str(item.get("type") or item.get("artifact_type") or "").lower()
    status = str(item.get("status") or item.get("state") or "").lower()
    artifact_id = item.get("id") or item.get("artifact_id")
    if artifact_id and "audio" in kind and artifact_id not in before:
        candidates.append((status, artifact_id))
if candidates:
    ready = [item for item in candidates if item[0] in {"completed", "complete", "ready", "done"}]
    print((ready or candidates)[-1][1])
' "$BEFORE_IDS" "$1"
}

ARTIFACT_ID=""
DEADLINE=$((SECONDS + AUDIO_MAX_WAIT_SECONDS))
while (( SECONDS < DEADLINE )); do
  ARTIFACTS_NOW=$("$NLM_BIN" list artifacts "$NOTEBOOKLM_NOTEBOOK_ID" --json 2>/dev/null || true)
  ARTIFACT_ID=$(extract_new_audio_id "$ARTIFACTS_NOW")
  if [[ -n "$ARTIFACT_ID" ]]; then
    break
  fi
  sleep "$AUDIO_POLL_SECONDS"
done

if [[ -z "$ARTIFACT_ID" ]]; then
  fail "音声生成の完了を待つ時間を超えました: $CREATE_OUTPUT"
fi

if ! "$NLM_BIN" download audio "$NOTEBOOKLM_NOTEBOOK_ID" \
  --id "$ARTIFACT_ID" \
  --output "$DOWNLOAD_TMP" \
  --no-progress >/dev/null 2>&1; then
  fail "生成済み音声をダウンロードできませんでした"
fi
if [[ ! -s "$DOWNLOAD_TMP" ]]; then
  fail "ダウンロードされた音声ファイルが空です"
fi

mkdir -p "$AUDIO_DIR"
mv "$DOWNLOAD_TMP" "$AUDIO_FILE"
log "音声を保存しました: $AUDIO_FILE"

if ! "$NLM_BIN" source delete "$SOURCE_ID" --confirm >/dev/null 2>&1; then
  log "警告: 一時ソースを削除できませんでした: $SOURCE_ID" >&2
else
  log "一時ソースを削除しました: $SOURCE_ID"
fi

exit 0
