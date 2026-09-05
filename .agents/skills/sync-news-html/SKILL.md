---
name: sync-news-html
description: report/配下の調査レポート1本をhistory/news.htmlに反映する。カード上限(6枚/セクション)を超えたら最も古いカードをhistory/archive.htmlへ循環させる。ユーザーが「このreportをnews.htmlに反映して」「news.html更新して」等と依頼したときに使う。
---

# ai_news news.html 継続更新

## 対象ファイル
- 入力: `report/*.md`。レポートは `YYYY-MM-DD_タイトル.md`（例: `2026-09-05_2027年生成AI本格組み込み戦略.md`）の形式で保存する。手順1で命名を正規化した後、ユーザーが対象を指定しなければ、ファイル名の日付プレフィックスが最も新しいファイルを対象にする（本文の整形などで更新日時が変わっても対象判定がぶれないようにする）。
- 出力: `history/news.html`(メイン)、`history/archive.html`(循環先)。

## 前提
- `history/news.html` は7つの固定テーマセクションを持つ: `#agent`(エージェンティックAI) `#japan`(国内実装) `#physical`(フィジカルAI) `#sovereign`(ソブリンAI) `#infra`(インフラ) `#society`(経済・社会) `#security`(セキュリティ)。新しいテーマは追加しない。
- 各セクションの `.news-card` 上限は6枚。
- 各 `.news-card` は `data-added="YYYY-MM-DD"`(追加日)と `data-report="ファイル名"`(出典)を持つ。この `data-report` は `history/reports-data.js` の `window.REPORTS` オブジェクトのキー(拡張子なしファイル名)と一致している必要がある。一致していれば、ユーザーがカードをタップした際に `history/report-modal.js` が自動的に元レポート全文をモーダル表示する(カード側のHTML構造・追加のマークアップは不要)。
- `history/archive.html` は同じ7テーマ・同じidを持つ「過去ログ」ページ。カード循環時のみ更新する。
- `history/daily.html`(AI DAILY LOG)は `everyday_news/*.md` を出典とする別系統のページで、`scripts/generate_daily_data.py` が生成する `history/daily-data.js` だけを読む。このスキルの対象外なので触らない。

## 手順

1. **ファイル名を確認・自動修正する。** 対象を選ぶ前に `report/*.md` を全件走査し、`YYYY-MM-DD_タイトル.md` 形式でないファイルがあれば、本文を変更せず、ファイルの作成日時を `YYYY-MM-DD` として先頭に付けて自動的にリネームする（macOSでは `stat` などで作成日時を取得する。取得できない場合のみ実行日を使い、その旨を報告する）。移動先が既に存在する場合は上書きせず処理を停止して報告する。リネームした各ファイルについて、`history/news.html` と `history/archive.html` に旧ファイル名の `data-report` 属性・`.src` 表示があれば新ファイル名へ更新する。この処理が完了してから、指定された対象、またはファイル名の日付プレフィックスが最も新しい対象を決定する。
2. 対象レポートを全文読む。改行のない一塊の文章で読みにくい場合は、先に `format-report` スキルを適用してから次に進む。読んだ際に `^^`(脚注マーカーの除去漏れと思われる不要記号)や `[cite: 数字, ...]` 形式の引用元マーカーが含まれていないか確認し、含まれていれば `report/*.md` 本体から全て削除して上書き保存する(モーダル表示時に文中へそのまま表示されるのを防ぐため)。
3. レポート内から news-card 化すべきトピックを洗い出す。固有名詞・具体的な数字を含む「見出しになる」情報を優先し、抽象的な一般論は避ける。
4. 洗い出した各トピックを、既存7テーマのうち最も近いものに割り当てる。無理に当てはまらない場合も、最も近いテーマに寄せる(新テーマは作らない)。
5. 重複判定: `history/news.html` の全 `.news-card` を確認し、同一企業・同一イベントを指すカードが既にあれば、新規カードは作らない。代わりに、そのカードの `.src` 表示テキストと `data-report` 属性の両方に、今回のレポートのファイル名を " / " 区切りで追記する。
6. 重複しないトピックは、該当セクションの `.news-grid` 末尾に新規 `.news-card` として追加する。書式:
   ```html
   <div class="news-card" data-added="YYYY-MM-DD" data-report="レポートファイル名">
     <div class="kicker">英大文字の短いラベル</div>
     <h3>数字や固有名詞を含む具体的な見出し</h3>
     <p>背景・数字・固有名詞を含む3〜4文の説明。</p>
     <div class="src">レポートファイル名</div>
   </div>
   ```
   - `data-added` は本日日付(YYYY-MM-DD)。
   - kicker/見出し/説明文の文体・トーンは既存カードの書きぶり(断定調、具体的な数字・固有名詞を含む、体言止めや「〜へ」で終わる見出し)に合わせる。要約・推測で内容を水増ししない。
7. カードを追加した各セクションについて `.news-card` の数を数える。6枚を超えていれば、そのセクション内で `data-added` が最も古いカードを1枚選び:
   - `history/news.html` の該当セクションから削除する。
   - `history/archive.html` の同じ id を持つセクションの `.news-grid` に追加する。既存の `archive-empty` プレースホルダー(`<p class="archive-empty">まだアーカイブされたカードはありません。</p>`)があれば、そのセクションから削除してからカードを追加する。
8. `history/news.html` の `hero-desc` 内「調査レポートN本を横断」と footer の「COMPILED FROM N RESEARCH REPORTS」の N を、`report/` 配下の実ファイル数(`ls report/*.md | wc -l` 相当)に更新する。
9. `.ticker` 内のテキストを更新する。今回追加した新規カードの見出しを要約したブレイキングニュース文を1〜2件、末尾に ` +++ ` 区切りで追記する。区切り件数が8件を超える場合は先頭(最も古い)の項目から削除し、総数をおおむね8件に保つ。
10. `history/news.html`(および循環が発生した場合は `history/archive.html`)を上書き保存する。
11. `python3 scripts/generate_reports_data.py` を実行し、`report/` 配下の全 `.md` から `history/reports-data.js` を再生成する(新規レポートの全文タップ表示に必要。既存レポートも含め毎回全件再生成するので、対象を絞る必要はない)。
12. 変更したファイル(`history/news.html`、循環時は `history/archive.html`、`history/reports-data.js`、ファイル名を修正した場合は変更前後の `report/*.md` 本体)を `git add` し、`"YYYY-MM-DD のAIニュースを追加"`(本日日付、既存コミットメッセージと同形式)で `git commit` する。続けて `git push` する。ai_newsはVercelとGit連携済みで、`main` へのpushが `history/` の本番デプロイ(https://ai-news-sandy-seven.vercel.app)を自動トリガーするため、pushまで完了させて初めて更新がユーザーに反映される。本スキルの手順12は「サイトを更新して」という依頼自体にpushの実行が含まれている(commitだけでは未完了)。
13. 作業内容を1〜2文で要約報告する: 追加したカード(セクション名・見出し)、循環して `history/archive.html` に移したカード、更新した統計値(レポート本数)、push完了とデプロイトリガー済みである旨。ファイル全文は貼り直さない。
