# ai_news

## 目的

毎日AIニュースを収集し、要約をLINEに配信する。生成したデータは静的サイト（`history/`配下）としても閲覧できる。

## 自動実行

- launchdジョブ名: `com.motoki.ainews.daily`
- 実行時刻: 毎日 7:00（JST）
- 起動スクリプト: `scripts/daily_news.sh`
  - `claude -p` でプロンプト（`scripts/daily_news_prompt.txt`）を実行し、結果を `SUMMARY:` 行から抜き出してmacOS通知（`osascript`）を出す
  - 生成データは `generate_daily_data.py` / `generate_reports_data.py` で `history/` 用のJSONに変換される
- ログ出力先: `logs/daily_news.log`（標準出力）/ `logs/daily_news.err.log`（標準エラー）

手動実行:

```bash
bash scripts/daily_news.sh
```

## LINE Bot アクセストークンの保管元（ハブ）

このリポジトリの `.claude/settings.local.json`（gitignore対象）に `LINE_CHANNEL_ACCESS_TOKEN` を保管している。**値そのものはこのREADMEには書かない。**

このリポジトリはLINE通知の実行元であると同時に、`line_calendar_bot` と `diary_video_digest` の双方から参照されるハブになっている。

## 外部依存（重要・変更禁止）

`everyday_news/<YYYYMM>.md` は `line_calendar_bot` から `raw.githubusercontent.com/motoki4869/ai_news/main/everyday_news/<YYYYMM>.md` 経由で実行時に取得されている。そのため以下は**本番障害に直結するため行わない**。

- リポジトリ名の変更
- 非公開化（現在 `isPrivate: false`）
- `everyday_news/` の配置・ファイル形式の変更

## ディレクトリ構成（抜粋）

- `everyday_news/` — 月別ニュース記録（`line_calendar_bot` が参照）
- `history/` — 日次ニュースの静的サイト（`daily.html` 等）
- `report/` — テーマ別の考察レポート（Markdown）
- `scripts/` — 収集・生成スクリプト一式
- `.claude/skills/` — `format-report` / `sync-news-html` スキル
- `.claude/hooks/line_notify.sh` — Write/EditフックでLINE通知を送るフック

## NotebookLM音声

日次ニュースの更新に成功すると、専用NotebookLMノートブックへ当日分のニュースセクションだけを渡して日本語の音声概要を生成します。NotebookLMが付けた音声タイトルとともに `history/daily.html` の日付選択画面から再生できます。

### 音声本体の置き場所（GitHub Releases）

音声は1本10〜40MBあり、Gitに入れるとリポジトリが月1GB近く肥大化する（Gitは過去コミットのblobを保持し続けるため後から消しても縮まない）。またGitHub Pagesの公開サイズ上限1GBにも1ヶ月ほどで達する。そのため**音声本体はGit管理せず、GitHub Releases（タグ `audio`）のアセットとして配信する**。リリースアセットはリポジトリサイズにカウントされない。

- 配信URL: `https://github.com/motoki4869/ai_news/releases/download/audio/YYYY-MM-DD.m4a`
- Gitで管理するのは目録のみ: `history/audio-data.js`（再生メタデータ）と `history/audio-titles.json`（タイトル）
- `history/audio/` は `.gitignore` 対象の一時置き場。**リリースへのアップロードを確認できた音声はローカルから毎回削除する**（本体はリリース側に残るので聴取に支障はない）
- アップロードに失敗した分だけが手元に残り、翌日の実行でリトライ対象になる
- ローカルに音声を残さないため、当日分が生成済みかどうかの判定もリリースのアセット一覧で行う
- `audio` リリース自体は初回セットアップ時に一度だけ手動で作成しておく必要がある（`gh release create audio --repo motoki4869/ai_news --title "AIニュース音声"` など）。`daily_news.sh` は既存リリースへのアップロード・アセット一覧取得のみを行い、リリース自体は作成しない
- `AUDIO_REPO`/`AUDIO_RELEASE_TAG` 環境変数でリポジトリ・タグ名を変更できるが、`history/daily.html` の `AUDIO_SRC_RE`（再生を許可するURLの固定パターン）は `motoki4869/ai_news` + `audio` タグ決め打ちなので、変更する場合は両方を合わせて直すこと

### 実行時の前提

初回だけ、`scripts/notebooklm_audio.env.example` を `scripts/notebooklm_audio.env` にコピーし、`NOTEBOOKLM_NOTEBOOK_ID` に「AIニュース音声」用ノートブックのIDを設定してください。NotebookLM Tools CLI (`nlm`) のログイン状態と、`gh` の認証（`repo` スコープ）も必要です。

```bash
cp scripts/notebooklm_audio.env.example scripts/notebooklm_audio.env
# scripts/notebooklm_audio.env のNOTEBOOKLM_NOTEBOOK_IDを編集
nlm login --check
gh auth status
```

### launchd実行時の注意

launchdは `.zshrc` を読まないためPATHが `/usr/bin:/bin:/usr/sbin:/sbin` に限られ、`python3` はmacOS標準の3.9系に解決される。スクリプト側は `PYTHON_BIN` / `GH_BIN` で実行ファイルを明示的に解決し、`generate_audio_data.py` は `from __future__ import annotations` で3.9でも動くようにしてある。**Pythonスクリプトに3.10以降の記法を足す場合はこの制約に注意すること**（手動実行ではHomebrewの新しいPythonが使われるため気づけない）。

音声生成は時間がかかる場合があります。NotebookLMの認証・通信・生成に失敗しても、ニュース更新自体は成功扱いで継続します。手動で試す場合は `bash scripts/generate_notebooklm_audio.sh YYYY-MM-DD` を実行してください。
