# HANDOFF (2026-11-03, from Codex)

## やっていたこと
11月2日の日次AIニュースが未生成という指摘への調査・補完。

## 完了済み
- 原因は電源断中の定時実行の取り逃し。Macは11月1日9:51にシャットダウンし、2日14:21に起動。ジョブは毎日6:30、RunAtLoad=false。現在の起動後の実行回数も0だった。
- 11月2日掲載分（11月1日の発表・報道）を5件補完。月別原本、日次データ、ネオクラウド用語を更新し、cd84fbaをorigin/mainへpush済み。
- READMEの時刻を実設定の6:30へ訂正。詳しい調査結果はdocs/daily-news-missed-run-2026-11-02.md。
- 関連テスト41件通過。origin/mainの5件検査も通過。
- 過去日分のLINE一斉通知は送っていない。起動設定・日次スクリプトの仕様変更は行っていない。

## 次の一手
- 翌朝6:30の日次実行を確認する。電源が入っていれば定時実行される設定は維持している。

## 音声の補完
- 11月2日分のNotebookLM音声「画面を飛び出し肉体を得るAI」を生成。既存audioリリースへのアップロードと音声目録の追加を確認済み。ログは/private/tmp/ai-news-recovery-audio-20261102.log。

## 注意点
- 未追跡のeveryday_news/line_message 2.txtは元ファイルと内容が異なるため、そのまま残した。
- 電源断で逃した過去日の自動補完は未実装。RunAtLoadだけを有効にしてもスクリプトは当日の日付を使うため、過去日の欠損は埋まらない。
- 以前のCodex隔離方式・認証・テストに関する記録は下記に保持。

---

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
- （完了）2026-10-06 17:15に`bash test/test_real_codex_sandbox.sh`を実行し、`codex exec`経由でも権限プロファイルが効くことを確認済み。
- 翌朝の定時実行のログ（`logs/daily_news.*.log`）でCodex経路が成功しているか確認する。

## 注意点・ハマりどころ
- `scripts/lib/agent-sandbox.sb`は廃止し、`_deleted/`へ退避済み。
- `~/Library/Caches/ai-news-codex-runtime/run.*`はCodexのログ等で実行ごとに増える。自動削除はファイル削除ポリシーのため未実装。
- cmuxのCodexフックがリポジトリ直下に`~/`ディレクトリを作ることがある（`~`を展開しないため）。今回の分は`_deleted/~`へ退避済み。
- `scripts/lib/codex_fallback.sh`はinvestmentリポジトリにも複製があるが、今回はai_news側だけを変更した。
- Codexのtool sandbox内から`codex sandbox`を呼ぶとSeatbeltの入れ子になり失敗する。テストは通常のmacOS環境で実行する。

## 関連ファイル
- `scripts/lib/codex_fallback.sh` — `CODEX_COMMAND_PERMISSIONS`と`run_codex`
- `scripts/daily_news.sh` — 開始前検査（staged/unstaged/未push）、同期、音声処理
- `test/test_codex_command_sandbox.sh` — 実CLIでのコマンド境界の確認
- `test/test_real_codex_sandbox.sh` — モデル呼び出しを伴う統合テスト（新方式で通過済み）
