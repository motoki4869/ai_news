# HANDOFF (2026-10-06 13:10, from Claude Code)

## やっていたこと
日次AIニュース更新の再発防止（Claude経由のLINE表示、最低5件保証、Codex/Claude実行の隔離、ユーザー編集の保護）。Codexからの引き継ぎを完了し、`origin/main`へpush済み。

## 完了済み
- Codexの隔離方式を「外側のSeatbelt」から「Codex自身の権限プロファイル（`CODEX_COMMAND_PERMISSIONS`）」に変更。コマンドは作業用コピーとシステムの最小限しか読み書きできず、本体repo・HOME・認証情報・/tmp・ネットワークに届かない。
- 認証JSONは`~/Library/Caches/ai-news-codex-runtime/run.*/home/.codex/`に一時コピーし、実行後に削除。実行中にCodexがトークンを更新した場合だけ`~/.codex/auth.json`へ書き戻す。
- mainに日次処理以外の未pushのcommitがあれば開始しない。音声一覧ファイルに未commitの編集があれば音声更新をスキップ。
- `test/test_codex_command_sandbox.sh`（実CLIの`codex sandbox`、API不要）を追加し、Homebrew版0.160.0とChatGPTアプリ同梱版0.158.0の両方で通過。
- ユーザー指示により、Codexへのクロスレビューは今後行わない。

## 次の一手
- Codexの利用上限が解けたら（2026-10-06 17:06以降）`bash test/test_real_codex_sandbox.sh`を通常環境で実行し、モデル経由の`codex exec`でも権限プロファイルが効くことを確認する。`codex exec`のヘッダーには`sandbox: workspace-write`と表示されるが、`codex sandbox`では独自プロファイルが効くことを確認済み。
- 翌朝の定時実行のログ（`logs/daily_news.*.log`）でCodex経路が成功しているか確認する。

## 注意点・ハマりどころ
- `scripts/lib/agent-sandbox.sb`は使われなくなった。削除（`_deleted/`へ退避）はユーザー確認待ち。
- `~/Library/Caches/ai-news-codex-runtime/run.*`はCodexのログ等で実行ごとに増える。自動削除はファイル削除ポリシーのため未実装。
- リポジトリ直下の`~/`ディレクトリ（`.cmuxterm/codex-turn-ledger.json`）は、cmuxのCodexフックが`~`を展開せずに作ったもの。コミットしていない。扱いはユーザー確認待ち。
- `scripts/lib/codex_fallback.sh`はinvestmentリポジトリにも複製があるが、今回はai_news側だけを変更した。
- Codexのtool sandbox内から`codex sandbox`を呼ぶとSeatbeltの入れ子になり失敗する。テストは通常のmacOS環境で実行する。

## 関連ファイル
- `scripts/lib/codex_fallback.sh` — `CODEX_COMMAND_PERMISSIONS`と`run_codex`
- `scripts/daily_news.sh` — 開始前検査（staged/unstaged/未push）、同期、音声処理
- `test/test_codex_command_sandbox.sh` — 実CLIでのコマンド境界の確認
- `test/test_real_codex_sandbox.sh` — モデル呼び出しを伴う統合テスト（新方式では未実行）
