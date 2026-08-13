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
