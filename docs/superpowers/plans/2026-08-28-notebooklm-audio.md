# NotebookLM音声連携 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 毎朝の `ai_news` 更新処理で当日分の記事本文だけをNotebookLMに渡して音声概要を生成し、`ai_news_daily` から過去分を含む音声を再生できるようにする。
**Architecture:** NotebookLMの専用ノートブックに当日分Markdownを一時ソースとして追加し、生成済み音声を `history/audio/YYYY-MM-DD.m4a` として保存する。音声一覧は記事データと分離した `history/audio-data.js` に出力し、静的ページの標準 `<audio>` プレイヤーから参照する。音声生成の失敗はニュース更新を失敗扱いにしない。
**Tech Stack:** Bash、Python標準ライブラリ、NotebookLM Tools CLI (`nlm`)、静的HTML/CSS/JavaScript、既存のVercel配信。

## Global Constraints

- 日本語で設計・運用ドキュメントを作成する。
- 既存のニュース更新と記事表示を壊さない。
- `history/audio/` の過去音声は削除・上書きせず保持する。
- NotebookLMの認証情報はリポジトリに保存しない。ノートブックIDだけをローカル設定に置き、設定ファイルはgit管理外にする。
- NotebookLMが利用できない場合も、ニュース更新・サイト更新は継続できるようにする。
- 実装前後に既存テストと追加テストを実行し、push前に静的サイトと音声ファイルの配信を確認する。

---

## Task 1: 当日セクション抽出と音声メタデータ生成を実装する

- [ ] `scripts/generate_audio_data.py` の期待仕様をテストで固定する。
  - `everyday_news/YYYYMM.md` から指定日の `## YYYY-MM-DD` セクションだけを抽出できる。
  - 指定日がない場合は明確なエラーにする。
  - `history/audio/` の `.m4a` だけを日付名から収集し、日付順のメタデータを出力する。
  - 出力JavaScriptは `window.DAILY_AUDIO` を設定し、HTMLエスケープ可能な値を安全に扱う。
- [ ] `test/test_generate_audio_data.py` を追加し、unittestで上記を検証する。
- [ ] テストを通す実装を追加する。CLIは、当日ソース抽出モードと音声一覧出力モードを持たせる。
- [ ] `python3 -m unittest discover -s test -p 'test_*.py'` を実行する。
- [ ] 変更を `feat: add audio metadata generation` としてコミットする。

## Task 2: NotebookLM音声生成スクリプトと設定例を追加する

- [ ] `scripts/generate_notebooklm_audio.sh` を追加する。
  - 当日セクションを一時Markdownに抽出する。
  - 専用ノートブックへ当日ソースを追加し、追加したソースIDだけで日本語音声を生成する。
  - 生成完了をポーリングし、ダウンロードを一時ファイル経由で `history/audio/YYYY-MM-DD.m4a` に保存する。
  - 生成済み音声とメタデータが既に存在し、git差分もない場合は再生成しない。
  - 当日ソースの追加・削除はタイトル接頭辞を限定し、既存の他用途ソースを触らない。
  - NotebookLMの失敗はログを残して終了コード0にし、ニュース更新を止めない。
- [ ] `scripts/notebooklm_audio.env.example` と `.gitignore` の設定例を追加する。実設定は `scripts/notebooklm_audio.env` とし、git管理外にする。
- [ ] `bash -n scripts/generate_notebooklm_audio.sh` と設定不足・CLI不足の失敗経路を検証する。
- [ ] 変更を `feat: add NotebookLM audio generation` としてコミットする。

## Task 3: 毎朝の更新処理へ非ブロッキングで組み込む

- [ ] `scripts/daily_news.sh` に音声生成呼び出しを追加する。
  - 既存のニュース更新ステータスを維持し、音声生成の終了コードでニュース更新を失敗にしない。
  - 音声生成後に `generate_audio_data.py` を実行し、音声一覧を更新する。
  - NotebookLM設定がない環境では警告だけ出して従来処理を継続する。
- [ ] `README.md` に初回設定、毎朝の処理、失敗時の扱い、音声保存場所を追記する。
- [ ] 既存テスト、shell構文、音声生成スクリプトのモック実行を確認する。
- [ ] 変更を `feat: integrate daily NotebookLM audio update` としてコミットする。

## Task 4: `ai_news_daily` に音声プレイヤーを追加する

- [ ] `history/daily.html` に `history/audio-data.js` の読み込みと音声プレイヤー領域を追加する。
- [ ] 日付選択時に該当日の音声を表示し、存在しない日は自然な空状態を表示する。
- [ ] 標準の `<audio controls preload='metadata'>` を使い、スマートフォンでも操作できるレイアウトにする。
- [ ] `history/audio-data.js` を生成し、既存のページ表示とモバイルCSSを確認する。
- [ ] 変更を `feat: add daily news audio player` としてコミットする。

## Task 5: 今日の音声を生成し、公開サイトへ反映する

- [ ] NotebookLMに専用ノートブック「AIニュース音声」を作成し、ローカル設定へIDを保存する。
- [ ] `2026-08-28` の記事セクションだけで音声を生成し、`history/audio/2026-08-28.m4a` を作成する。
- [ ] 音声メタデータを生成し、ローカルHTTP配信でHTMLとM4Aの参照を確認する。
- [ ] Vercel本番へpushし、`ai_news_daily` で当日音声が表示され、音声ファイルがHTTP取得できることを確認する。
- [ ] push前に `git diff --check` と全テストを実行する。
- [ ] 最終変更をコミットしてpushする。既存の設計書・計画書・実装・今日の音声メタデータを同じリポジトリに残す。

## 完了条件

- 毎朝のスクリプトが当日分のニュース更新後に音声生成を試行する。
- 音声生成に失敗してもニュース更新は成功扱いで継続する。
- 過去の生成済み音声が保持され、日付選択で再生できる。
- 今日（2026-08-28）の音声がサイト上で確認できる。
- 実装、設計、実行計画が `ai_news` リポジトリに保存され、変更がpush済みである。
