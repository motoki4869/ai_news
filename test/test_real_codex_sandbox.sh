#!/bin/bash
# macOS の実 Codex CLI と Seatbelt を使う統合テスト。手動で通常環境から実行する。
set -euo pipefail

SCRIPT_ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
if [ "$(uname -s)" != Darwin ] || [ ! -x /usr/bin/sandbox-exec ]; then
  echo "macOS の sandbox-exec が必要です" >&2
  exit 1
fi

real_codex_bin="${REAL_CODEX_BIN:-/opt/homebrew/bin/codex}"
if [ ! -x "$real_codex_bin" ] || ! "$real_codex_bin" --version | grep -q 'codex-cli'; then
  echo "実際の Codex CLI が必要です: $real_codex_bin" >&2
  exit 1
fi

scratch="$(mktemp -d "${TMPDIR:-/private/tmp}/ai-news-real-codex-test.XXXXXX")"
scratch="$(cd "$scratch" && pwd -P)"
outside_probe="$(dirname "$scratch")/$(basename "$scratch").outside"
printf 'real-codex-read-ok\n' > "$scratch/input.txt"
printf '%s\n%s\n%s\n' "$SCRIPT_ROOT" "$HOME" "$outside_probe" > "$scratch/probe-paths.txt"
cat > "$scratch/probe.sh" <<'SH'
#!/bin/sh
set -eu
{
  IFS= read -r original_repo
  IFS= read -r original_home
  IFS= read -r outside_probe
} < probe-paths.txt
/bin/cat input.txt > output.txt
if /bin/cat "$original_repo/README.md" >/dev/null 2>&1; then exit 21; fi
if /bin/cat "$original_home/.codex/auth.json" >/dev/null 2>&1; then exit 22; fi
if /bin/ls "$original_home/.ssh" >/dev/null 2>&1; then exit 23; fi
if printf forbidden > "$outside_probe" 2>/dev/null; then exit 24; fi
printf 'boundary-ok\n' > boundary.txt
SH
printf '%s\n' '必ずシェルコマンド `/bin/sh ./probe.sh` を実行してください。終了後は DONE とだけ返してください。' > "$scratch/prompt.txt"

source "$SCRIPT_ROOT/scripts/lib/codex_fallback.sh"
if ! CODEX_BIN="$real_codex_bin" CODEX_FALLBACK_MODEL="${CODEX_REAL_TEST_MODEL:-gpt-6-sol}" \
  run_codex "$scratch" "$scratch/prompt.txt" "$SCRIPT_ROOT" > "$scratch/codex.log" 2>&1; then
  tail -50 "$scratch/codex.log" >&2
  echo "実 Codex の起動またはコマンド実行に失敗しました: $scratch" >&2
  exit 1
fi
if [ "$(cat "$scratch/output.txt" 2>/dev/null)" != real-codex-read-ok ] \
   || [ "$(cat "$scratch/boundary.txt" 2>/dev/null)" != boundary-ok ] \
   || [ -e "$outside_probe" ] \
   || [ -n "$(find "$scratch" -path '*/.codex/auth.json' -print -quit)" ]; then
  tail -50 "$scratch/codex.log" >&2
  echo "実 Codex のファイル読み取り、コマンド実行、隔離境界の検証に失敗しました: $scratch" >&2
  exit 1
fi
echo "実 Codex のコマンド実行と作業用コピー読み書き、repo・認証情報・外部書き込みの拒否を確認しました: $scratch"
