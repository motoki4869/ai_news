# AI DAILY LOG ページ設計書

作成日: 2026-08-02

## 目的

`everyday_news/YYYYMM.md` に毎朝蓄積されている日次AIニュースログを、AI NEWS FEED サイト上で閲覧できるようにする。ページ上部のカレンダーで日付を選ぶと、その日のニュースがカード形式で並ぶ。

## 背景

- サイト本体は `history/` 配下の静的HTML。Vercel と Git 連携済みで、`main` への push が `history/` を公開ルートとする本番デプロイ (https://ai-news-sandy-seven.vercel.app) を自動トリガーする。
- 公開ルートが `history/` であるため、リポジトリ直下の `everyday_news/*.md` はブラウザから直接 fetch できない。`history/` 配下に生成物を置く必要がある。
- 既存の `report/*.md` は `scripts/generate_reports_data.py` で `history/reports-data.js` に変換され、`window.REPORTS` としてページから参照されている。本機能はこの確立済みパターンをそのまま踏襲する。
- `everyday_news/*.md` の形式は 2026-08-02 時点で 24日分・141項目すべてが `- **見出し**: 本文（[出典](URL)）。` に一致し、例外行は存在しない。

## スコープ外

- `history/news.html` の7テーマ構成・カード循環ロジックには一切触れない。
- 日次ログ全体を横断する全文検索は実装しない。
- `history/reports-data.js` / `history/report-modal.js` は変更しない。

## 成果物

| 種別 | ファイル | 役割 |
|---|---|---|
| 新規 | `history/daily.html` | AI DAILY LOG ページ本体（カレンダー＋カード） |
| 新規 | `history/daily-data.js` | 生成物。`window.DAILY_NEWS` に全日次ログを格納 |
| 新規 | `scripts/generate_daily_data.py` | `everyday_news/*.md` から `daily-data.js` を全件再生成 |
| 変更 | `history/index.html` | ナビに「デイリー」リンクを追加 |
| 変更 | `history/news.html` | ナビに「デイリー」リンクを追加 |
| 変更 | `history/archive.html` | ナビに「デイリー」リンクを追加 |
| 変更 | `scripts/daily_news_prompt.txt` | 手順9にスクリプト実行と `daily-data.js` の git add を追加 |

## コンポーネント設計

### `scripts/generate_daily_data.py`

`generate_reports_data.py` と同じ構造・同じ配置ルールに従う単一責務のスクリプト。

**入力**: `everyday_news/*.md`（`line_message.txt` は対象外）
**出力**: `history/daily-data.js`

**パース規則**

- `## YYYY-MM-DD` 形式の行を日付キーとして認識する。
- 日付見出しの下に続く `- ` で始まる行を1項目として扱う。
- 各項目を正規表現 `^- \*\*(.+?)\*\*[:：]\s*(.*)$` で見出しと本文に分解する。
- 本文末尾の `（[出典](URL)）` および前後の句点を取り除き、URL を別フィールドとして保持する。
- 本文中に残る `**強調**` は `<strong>` に変換する。それ以外のインラインマークアップは変換しない。
- `# <YYYY年M月> AIニュースまとめ` のファイル先頭見出しと空行は無視する。

**出力形式**

```js
window.DAILY_NEWS = {
  "2026-08-01": [
    {
      "title": "OpenAI、GPT-5.6の廉価モデル「Luna」「Terra」を大幅値下げ",
      "body": "7月30日、サービング効率の改善を理由に…",
      "url": "https://www.cnbc.com/2026/07/30/open-ai-price-cut-gpt.html"
    }
  ]
};
```

キーは日付文字列の昇順。値は md 中の出現順を保つ配列。

**エラー方針**

パースできない行（`- ` で始まるが見出し形式に一致しない、`出典` リンクが取れない、など）を検出したら、その行のファイル名・行番号・内容を stderr に出力し、**終了コード1で異常終了する**。毎朝の自動ジョブに組み込むため、形式が変わったときに項目を黙って取りこぼすことを防ぐ。異常終了時は `daily-data.js` を書き換えない。

正常終了時は標準出力に `generated <path> (<日数> days, <項目数> items)` を出す。

### `history/daily-data.js`

生成物。人手で編集しない。`daily.html` から `<script src="daily-data.js">` で読み込む。

### `history/daily.html`

`history/news.html` と同じダークサイバー調（CSS変数、ネオン発光、`neural-bg` キャンバス、グリッドオーバーレイ、スクロールプログレスバー）を踏襲する自己完結ファイル。既存3ページと同じく1ファイル1ページの構成に合わせ、必要な範囲のCSSのみを持たせる（`news.html` の全CSSを丸写ししない）。

**ナビ**

`AI DAILY LOG` ロゴ＋ `最新ニュース` `過去ログ` `← AI HISTORY` のリンク。`news.html` のナビと同じ見た目。

**カレンダー**

- 日〜土の7列月グリッド。ヘッダは `◀ 2026年8月 ▶`。
- 月送りボタンは、データが存在する最古の月〜最新の月の範囲外へは進めない（範囲端で disabled）。
- セルの状態は3種類:
  - **ニュースあり**: ネオン発光 + 件数バッジ。クリック可。
  - **ニュースなし**: 減光表示。クリック不可（`pointer-events: none` ではなく disabled 属性相当の扱いにし、フォーカスも取らない）。
  - **選択中**: 塗りつぶし。
- 初期表示はデータが存在する最新日。その日を含む月を開く。
- `◀ 最新` ボタンで初期表示日へ戻れる。「今日」ボタンにはしない（当日分のログが未生成のとき空振りするため）。
- URL ハッシュ `daily.html#2026-07-19` で特定日に直リンクできる。ロード時にハッシュを読み、該当日にデータがあればその日を選択する。無効なハッシュは無視して最新日を表示する。日付選択時は `history.replaceState` でハッシュを同期する（履歴を汚さない）。
- `←` `→` キーで、ニュースが存在する前後の日へジャンプする。月をまたぐ場合はカレンダー表示月も追従する。
- スマホ幅ではセル寸法とフォントを縮め、7列レイアウトを維持する。

**カードエリア**

選択日の項目を `news.html` と同じ `.news-grid`（レスポンシブ多段グリッド）に並べる。カード1枚 = 項目1件。

- **キッカー**: 出典URLのドメインを大文字で表示（例: `CNBC.COM`）。md にカテゴリ情報が無いため、既存カードのキッカー枠を出典表示に流用する。
- **h3**: 見出し。
- **p**: 要約全文。
- **フッター**: `出典を読む →`（`target="_blank" rel="noopener"`）。

日次ログは1項目が数行と短いため、`report-modal.js` のようなタップ→モーダル展開は使わず、全文をカード内に表示し切る。

カードエリアの上には選択日の見出し（例: `2026-08-01（土）— 5件`）を出す。

### ナビリンクの追加

`index.html` `news.html` `archive.html` の3ページのナビに `daily.html` へのリンクを追加する。各ページの既存リンクと同じマークアップ・配色ルールに従う。

### `scripts/daily_news_prompt.txt` の変更

現行の手順9は「`everyday_news/<YYYYMM>.md` をコミットして push」となっている。ここに以下を加える。

- コミット前に `python3 scripts/generate_daily_data.py` を実行する。
- 異常終了した場合はコミット・push を行わず、エラー内容を報告して終了する。
- 正常終了した場合、`git add` の対象に `history/daily-data.js` を含める。

コミットメッセージの形式（`<YYYY-MM-DD> のAIニュースを追加`）と push 先（`main`）は変更しない。

## データフロー

```
毎朝 launchd
  → scripts/daily_news.sh
    → claude -p (daily_news_prompt.txt)
      → WebSearch でニュース収集
      → everyday_news/<YYYYMM>.md に追記
      → everyday_news/line_message.txt を生成（gitignore対象）
      → python3 scripts/generate_daily_data.py
        → history/daily-data.js を全件再生成
      → git add everyday_news/<YYYYMM>.md history/daily-data.js
      → git commit && git push
        → Vercel が history/ を自動デプロイ
          → daily.html が最新日を初期表示
```

## 検証

1. `python3 scripts/generate_daily_data.py` を実行し、警告ゼロで正常終了することを確認する。出力された日数・項目数が、`everyday_news/*.md` を直接数えた `## ` 見出し数・`- ` 行数と一致することを確認する（2026-08-02 時点の実データは 24日分・141項目。日次ジョブが走れば増える）。
2. 形式を意図的に崩した md を一時ファイルで用意し、スクリプトが stderr に該当行を出して終了コード1で落ちること、`daily-data.js` が書き換わらないことを確認する。
3. Chrome で `history/daily.html` を開いて実機確認する。
   - 初期表示が最新日になっている
   - 8月グリッドの1日をクリックしてカードが表示される
   - `◀` で7月へ月送りでき、7月の任意日を選べる
   - データのない日がクリックできない
   - `←` `→` キーでニュースのある前後日へ移動する
   - `daily.html#2026-07-19` で直接その日が開く
   - スマホ幅（375px相当）でカレンダーが7列を保ち、カードが1列で読める
   - 3ページのナビから daily.html に到達できる
4. 検証用に撮ったスクリーンショットは、確認完了後に削除する（グローバル CLAUDE.md のスクリーンショット証跡管理方針に従う）。
