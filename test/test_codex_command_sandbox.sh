#!/bin/bash
# 実Codex CLIの `codex sandbox` で、日次処理と同じ権限プロファイルの境界を確認する。
# モデルを呼ばないためAPI利用枠を消費しない。macOSの通常環境で実行する。
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
real_codex_bin="${REAL_CODEX_BIN:-$(command -v codex || echo /opt/homebrew/bin/codex)}"
if [ "$(uname -s)" != Darwin ] || [ ! -x "$real_codex_bin" ]; then
  echo "macOSと実際のCodex CLIが必要です: $real_codex_bin" >&2
  exit 1
fi
source "$SCRIPT_ROOT/scripts/lib/codex_fallback.sh"

tmp_base="$(cd "${TMPDIR:-/tmp}" && pwd -P)"
workspace="$(mktemp -d "$tmp_base/ai-news-command-sandbox.XXXXXX")"
codex_home="$(mktemp -d "$HOME/Library/Caches/ai-news-command-sandbox.XXXXXX")"
outside_probe="$tmp_base/$(basename "$workspace").outside"
cleanup() {
  rm -f "$outside_probe" /private/tmp/ai-news-command-sandbox.outside
  local dir
  for dir in "$workspace" "$codex_home"; do
    find "$dir" ! -type d -delete
    find "$dir" -depth -type d -exec rmdir {} +
  done
}
trap cleanup EXIT
printf '{"secret":true}\n' > "$codex_home/secret.json"

cat > "$workspace/probe.sh" <<SH
#!/bin/sh
fail() { echo "FAIL: \$1"; exit 1; }
printf ok > ./inside.txt || fail '作業用コピーへ書き込めません'
[ "\$(cat ./inside.txt)" = ok ] || fail '作業用コピーを読めません'
if /bin/cat "$SCRIPT_ROOT/README.md" >/dev/null 2>&1; then fail '本体repoを読めました'; fi
if /bin/cat "$codex_home/secret.json" >/dev/null 2>&1; then fail 'CODEX_HOMEの認証情報を読めました'; fi
if /bin/ls "$HOME/.ssh" >/dev/null 2>&1; then fail '~/.sshを読めました'; fi
if /bin/ls "$tmp_base" >/dev/null 2>&1; then fail '作業用コピーの親ディレクトリを読めました'; fi
if printf x > "$outside_probe" 2>/dev/null; then fail '作業用コピーの外へ書き込めました'; fi
if printf x > /private/tmp/ai-news-command-sandbox.outside 2>/dev/null; then fail '/tmpへ書き込めました'; fi
if /usr/bin/curl -sS -m 5 https://example.com >/dev/null 2>&1; then fail 'ネットワークに接続できました'; fi
echo BOUNDARY_OK
SH

output="$(cd "$workspace" && /usr/bin/env -u NODE_OPTIONS \
  HOME="$codex_home" CODEX_HOME="$codex_home" \
  "$real_codex_bin" sandbox "${CODEX_COMMAND_PERMISSIONS[@]}" -- /bin/sh ./probe.sh 2>&1)" || true
if [ "${output##*$'\n'}" != BOUNDARY_OK ] || [ -e "$outside_probe" ] || [ -e /private/tmp/ai-news-command-sandbox.outside ]; then
  printf '%s\n' "$output" >&2
  echo "Codexのコマンド用サンドボックスの境界が想定どおりではありません" >&2
  exit 1
fi
echo "SUMMARY: Codexのコマンドは作業用コピーだけを読み書きでき、本体repo・認証情報・HOME・/tmp・ネットワークに届かないことを確認しました"
