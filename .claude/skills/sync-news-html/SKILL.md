---
name: sync-news-html
description: report/配下の調査レポート1本をhistory/news.htmlに反映する。カード上限(6枚/セクション)を超えたら最も古いカードをhistory/archive.htmlへ循環させる。ユーザーが「このreportをnews.htmlに反映して」「news.html更新して」等と依頼したときに使う。
---

# ai_news news.html 継続更新

## 対象ファイル
- 入力: `report/*.md`。ユーザーが対象を指定しなければ、`report/` 内で最終更新日時が最も新しいファイルを対象にする。
- 出力: `history/news.html`(メイン)、`history/archive.html`(循環先)。

## 前提
- `history/news.html` は7つの固定テーマセクションを持つ: `#agent`(エージェンティックAI) `#japan`(国内実装) `#physical`(フィジカルAI) `#sovereign`(ソブリンAI) `#infra`(インフラ) `#society`(経済・社会) `#security`(セキュリティ)。新しいテーマは追加しない。
- 各セクションの `.news-card` 上限は6枚。
- 各 `.news-card` は `data-added="YYYY-MM-DD"`(追加日)と `data-report="ファイル名"`(出典)を持つ。
- `history/archive.html` は同じ7テーマ・同じidを持つ「過去ログ」ページ。カード循環時のみ更新する。

## 手順

1. 対象レポートを全文読む。改行のない一塊の文章で読みにくい場合は、先に `format-report` スキルを適用してから次に進む。
2. レポート内から news-card 化すべきトピックを洗い出す。固有名詞・具体的な数字を含む「見出しになる」情報を優先し、抽象的な一般論は避ける。
3. 洗い出した各トピックを、既存7テーマのうち最も近いものに割り当てる。無理に当てはまらない場合も、最も近いテーマに寄せる(新テーマは作らない)。
4. 重複判定: `history/news.html` の全 `.news-card` を確認し、同一企業・同一イベントを指すカードが既にあれば、新規カードは作らない。代わりに、そのカードの `.src` 表示テキストと `data-report` 属性の両方に、今回のレポートのファイル名を " / " 区切りで追記する。
5. 重複しないトピックは、該当セクションの `.news-grid` 末尾に新規 `.news-card` として追加する。書式:
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
6. カードを追加した各セクションについて `.news-card` の数を数える。6枚を超えていれば、そのセクション内で `data-added` が最も古いカードを1枚選び:
   - `history/news.html` の該当セクションから削除する。
   - `history/archive.html` の同じ id を持つセクションの `.news-grid` に追加する。既存の `archive-empty` プレースホルダー(`<p class="archive-empty">まだアーカイブされたカードはありません。</p>`)があれば、そのセクションから削除してからカードを追加する。
7. `history/news.html` の `hero-desc` 内「調査レポートN本を横断」と footer の「COMPILED FROM N RESEARCH REPORTS」の N を、`report/` 配下の実ファイル数(`ls report/*.md | wc -l` 相当)に更新する。
8. `.ticker` 内のテキストを更新する。今回追加した新規カードの見出しを要約したブレイキングニュース文を1〜2件、末尾に ` +++ ` 区切りで追記する。区切り件数が8件を超える場合は先頭(最も古い)の項目から削除し、総数をおおむね8件に保つ。
9. `history/news.html`(および循環が発生した場合は `history/archive.html`)を上書き保存する。
10. 作業内容を1〜2文で要約報告する: 追加したカード(セクション名・見出し)、循環して `history/archive.html` に移したカード、更新した統計値(レポート本数)。ファイル全文は貼り直さない。
