# HANDOFF (2026-10-06 12:28, from Codex)

## やっていたこと
日次AIニュース更新で、Claude Code経由のLINE表示が抜けることと、ニュースが1件でも成功扱いになることを再発防止する修正。Codex/Claudeの隔離、最低5件保証、更新対象の競合保護を実装中。ユーザー指示により、ここから先の作業はClaude Codeが引き継ぐ。

## 完了済み
- `8c1f474` でClaude経由のLINE表示、重複除外後の最低5件検査を追加。
- `a3738de` と `01d9a84` で親スクリプト側のcommit/push、独立したAI作業コピー、重複記事の推移的な統合、通常Git indexの保全を追加。
- `237d7da` でCodex/Claude実行隔離、開始時staged変更の拒否、実行中の同時編集検出、成功SUMMARYと5件検査後のみ同期する処理を追加。Solの実装後、Claude Opusのクロスレビューで追加指摘が見つかった。
- 追加指摘の実装は未コミットで作業ツリーにある。SolはCodex実行を外側のmacOS Seatbeltだけにし、内側Codex sandboxを`danger-full-access`に変更。使い捨てHOME/CODEX_HOMEを作業コピー配下に置き、元repo・元HOME・SSH等を拒否する方式へ変更。実CLIで、scratch内の読み書き成功と元repoへのアクセス拒否を確認した（Solの実行ログ `/private/tmp/ai-news-sol-review-fixes.log`）。
- 未コミット差分に、開始前unstaged変更の拒否、音声commit/pushにも5件フックを適用、成功後にClaude/Codex経路マーカーを毎回更新、未追跡Markdownもデータ生成用scratchへコピーする修正を含む。
- `test/test_real_codex_sandbox.sh` を追加したが、最終版でまだ実行していない。
- Solの直近実装を止めた。追加差分はWIP commit済み。Solの作業中プロセスは終了済み。

## 次の一手
- まず `git status -sb` と `git log --oneline -5` を確認する。WIP commit後もローカルmainはoriginより先行している。` .playwright-mcp/` は元からの無関係な未追跡物なので追加・変更しない。
- Solの未コミット分に対して、`bash scripts/lib/test_codex_fallback.sh`、`bash test/test_daily_news.sh`、`bash test/test_news_update_lock.sh`、Python unittest、`node --test test/*.js`、`git diff --check`を再実行する。`sandbox-exec`テストはCodexの内側sandbox内から呼ぶと`Operation not permitted`になるため、通常のmacOS環境で実行する。
- `bash test/test_real_codex_sandbox.sh`を通常環境で実行し、Codexの実CLIが作業コピーを読めて書けること、本repo・元HOME/SSH情報・作業コピー外へアクセスできないことを確認する。Codex API利用が必要。
- 差分を確認し、特にCodex認証JSONのコピー/削除、外側Seatbeltの許可範囲、音声再試行経路、未追跡Markdownの生成データ反映、元repoのunstaged編集をpushしないことを点検する。git shim alias回避の指摘も隔離方式に照らして判断する。
- `docs/CHANGELOG.md`にWIP分を追記・更新する。
- 最後にクロスレビューを一度実施する。Solへの最初のレビューは実施済み、Claude Opusレビューで下記の重大/Medium指摘が出ており、Solが対処中だった。
- すべて解決したら既存の `origin/main` へpushし、`git status -sb`を確認する。ユーザーは「ここから残りはClaude Codeに」と指示している。

## 注意点・ハマりどころ
- 直近のClaude Opusレビュー（`8c1f474...HEAD`）のCriticalは「外側sandbox-execとCodexの内側workspace-write sandboxを重ねるとmacOSで内側sandboxが起動せず、実Codexのファイル読み取りが失敗」。Solは外側Seatbeltのみへ変更し、`danger-full-access`で実CLI動作を確認したが、追加した最終統合テストは未実行。
- 同レビューのMediumは「開始前のunstaged編集を日次commitへ含める」「音声commit/pushが5件フックを通らない」「未追跡Markdownが生成データから漏れる」。Solの現在の差分では対策コードと回帰テストを追加したが、未検証。
- 同レビューのLowは「Claude経路マーカーが同日の後続Codex成功後も残る」「scratch作業コピーが蓄積」「git shimは短縮aliasで回避可能」。Solは経路マーカーを更新するテストを追加。作業コピーの自動削除はユーザーのファイル削除方針により追加していない。alias指摘は確認が必要。
- Solのテスト実行はCodex tool sandbox内だったため、`sandbox-exec`を呼ぶ`test_codex_fallback.sh`が失敗した。これは隔離方式の回帰失敗とは限らない。こちらでは前の版で通常環境の`test_codex_fallback.sh`と`test/test_daily_news.sh`が成功しているが、Sol追加後の最終版は未確認。
- Solの直接レビュー/実装用Codex呼び出しは途中で利用上限に到達したことがある。現在はユーザー指定でClaude Codeへ引き継ぐ。
- 現在のコード差分はGitで引き継ぐ。HANDOFFは次の引継ぎ時も削除せず上書きする。

## 関連ファイル
- `scripts/daily_news.sh` — 日次更新、隔離scratch、生成/検証、commit・push・音声再試行
- `scripts/lib/codex_fallback.sh` — Codex/Claudeの起動境界とフォールバック
- `scripts/lib/agent-sandbox.sb` — Codex実行時のmacOS Seatbelt
- `scripts/validate_daily_news.py` — 重複除外後の最低5件検査
- `test/test_daily_news.sh`、`scripts/lib/test_codex_fallback.sh` — 日次処理の回帰テスト
- `test/test_real_codex_sandbox.sh` — 実Codex CLI隔離の統合テスト（未実行）
