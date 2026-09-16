# CHANGELOG

ai_news の変更履歴。新しい日付を上に追記する。
記録対象は見た目・挙動が変わる変更のみ（内部リファクタ・日次の自動データコミットは含めない）。

---

## 2026-09-17

### 未使用フォントウェイトの読み込みを停止
- **変更**: 全6ページのGoogle Fonts指定から、使用箇所ゼロの `Noto Sans JP 500` と `JetBrains Mono 600` を外し、代わりに実際に使われている `JetBrains Mono 700`（`<strong>` のブラウザ既定太字）を追加した。フォント定義CSSは 465KB → 350KB（-112KB、@font-face 511件 → 387件）。ウェイト選定の根拠をHTMLコメントで残した。
- **理由**: Noto Sans JP は和文の字数が多く、Google Fontsが1ウェイトあたり100以上の `@font-face` に分割して配信するため、使わないウェイトが1つあるだけで全ページ共通の初期コストが数十KB増える。500は全6ページのCSSで一度も指定されておらず、実描画でも出現しなかった。逆に `JetBrains Mono 700` は用語集の12箇所で要求されているのに未読み込みで、近似の600で描画されていた。
- **対象**: `history/index.html`, `history/generative.html`, `history/news.html`, `history/daily.html`, `history/archive.html`, `history/glossary.html`
- **確認**: 全6ページでDOM全要素の計算済み `font-weight` を集計し、変更前後で完全一致することを確認（`Noto 300/400/700`、`Orbitron 400/600/800`、`JetBrains 400`、`<strong>` の700）。`document.fonts` の読み込み済みフェイスは `JetBrains Mono 600` → `700` のみが差分。用語集のスクリーンショット比較でも見た目の差は無し。
- **commit**: `HEAD`（今回の実装コミット）

### LINE通知のリンク先を当日の日次ログに変更
- **変更**: 毎朝のLINE通知に載せるURLを、サイトのルート（`https://ai-news-sandy-seven.vercel.app`）から `https://ai-news-sandy-seven.vercel.app/daily.html#YYYY-MM-DD` に変更した。日付は送信権の重複判定で使っている `LINE_NOTIFY_DATE`（未設定なら当日）と同じ値を使う。
- **理由**: 「本日のAI_newsが更新されました」という通知なのに、開くと1950年から続くAI HISTORYの年表が出て、更新された当日分のニュースまで自分でナビゲートする必要があった。
- **対象**: `scripts/lib/line_notification_dedupe.sh`, `scripts/lib/test_line_notification_dedupe.sh`
- **確認**: 本番の `daily.html#2026-09-16` / `#2026-09-10` で該当日が選択されること、存在しない日付（`#2026-12-31`）では最新日にフォールバックして壊れないことをブラウザで確認。テスト8件すべてPASS。
- **commit**: `HEAD`（今回の実装コミット）

## 2026-09-16

### Vercel Analyticsの時間別データをローカル保存
- **変更**: 前日のWeb Analyticsを毎日取得し、日本時間の1時間ごとのVisitors数とPage Views数を `data/analytics/vercel_web_analytics_hourly.csv` に保存するスクリプトとlaunchd設定を追加した。同じ日を再取得しても行が重複しない。
- **理由**: Vercel Hobbyプランの保存期間を超えても、社内公開後のアクセス推移を手元で確認できるようにするため。
- **対象**: `scripts/collect_vercel_analytics.py`, `scripts/collect_vercel_analytics.sh`, `scripts/com.motoki.ainews.analytics.plist`, `test/test_collect_vercel_analytics.py`, `.gitignore`, `README.md`
- **commit**: `HEAD`（今回の実装コミット）

### Vercel Analyticsの未取得日の自動埋め戻し
- **変更**: launchd実行時にローカルCSVの未取得日を確認し、前日分を毎回更新しながら、初回記録日以降の未取得日を最大30日分まで順番に取得するようにした。通信失敗日は保留ファイルへ記録して、CSVへ書き込まず次回実行時に再試行する。
- **理由**: Macの電源オフやAPI障害で午前1時の実行に失敗しても、後日の実行でアクセス記録が抜けないようにするため。
- **対象**: `scripts/collect_vercel_analytics.py`, `test/test_collect_vercel_analytics.py`, `README.md`
- **commit**: `HEAD`（今回の実装コミット）

### 自分のブラウザをVercel Analyticsの計測対象から除外
- **変更**: `?analytics=off` を一度開くと、そのブラウザの `localStorage` に除外設定を保存し、`ai_news` 全ページでAnalyticsスクリプトを読み込まないようにした。`?analytics=on` で除外設定を解除できる。除外判定はブラウザ単位で、他の利用者や別端末には影響しない。
- **理由**: サイト管理者自身のスマホからの頻繁な確認で、訪問者数・ページビュー数が実際の利用状況より多く見えるのを防ぐため。
- **対象**: `history/analytics.js`, `history/` 配下の6ページ, `test/test_vercel_analytics.sh`, `test/test_vercel_analytics_opt_out.js`
- **commit**: `HEAD`（今回の実装コミット）

### Vercel Web Analyticsによるアクセス計測を追加
- **変更**: VercelプロジェクトでWeb Analyticsを有効化し、`history/` 配下の6ページにページビュー・訪問者数を計測するスクリプトを追加。設定反映のため本番環境も再デプロイした。
- **理由**: サイトを社内公開した後のアクセス状況を確認できるようにし、今後の訪問者数を記録するため。
- **対象**: `history/index.html`, `history/news.html`, `history/daily.html`, `history/generative.html`, `history/glossary.html`, `history/archive.html`, Vercelプロジェクト設定
- **commit**: `ae16494`, `42e41d4`

### 過去ログページに絞り込みを追加
- **変更**: `archive.html` にキーワード検索ボックスと7テーマのクイックフィルターを追加。NEWS FEEDと同じ仕様（検索とテーマの併用可、同じボタンの再押下で解除、該当0件のテーマは見出しごと非表示）に揃えた。配色のみこのページのアクセントであるamber/coralに合わせ、NEWS FEEDには無い「該当なし」の案内文を追加した。
- **理由**: 過去ログが42件まで増え、目的のトピックを探す手段が無かったため。
- **対象**: `history/archive.html`
- **確認**: ローカルで全42件→「インフラ」6件→再押下で42件復帰、「NVIDIA」で4件ヒット、0件時の案内表示、横スクロール無しを確認。
- **commit**: `30dc0ac`

### AI HISTORY / GENERATIVE ERA の内容を9月時点まで更新
- **変更**: 2026年の記述が7月時点で止まっていたため、7〜9月の出来事を `generative.html` に8件追加（GPT-5.6一般提供、中国オープンモデルと蒸留問題、Anthropic初の営業黒字、封じ込め逸脱、Fable 5.1、GPT-6 Astra、AIによる数学への挑戦、意図的減速の提言）。モデル系譜4枚の最新ノードを更新し、技術革新にワールドモデルを7つ目として追加。`index.html` は2026年のカードを書き直したうえで1枚追加し、MILESTONESを24→25に更新した。
- **理由**: 事実誤りが1件あった。Gemini 3.5 Proを「一般提供は7月に延期」と断定していたが、実際には目標を三度逃して9月時点でも未提供であり、当時の「予定」がそのまま断定文として残っていた。あわせて1950〜2025年の全記述を照合し、そちらには誤りが無いことを確認済み。
- **対象**: `history/generative.html`, `history/index.html`
- **commit**: `c85f9b0`

### sync-news-html スキルに年表ページ追記の手順を追加
- **変更**: 週次でnews.htmlを更新した際に、年表ページ（`index.html` / `generative.html`）への追記要否を判断する手順13を追加。追記基準、既存カードとの重複確認、追記先の選び方、両ページのHTML書式を明記した。
- **理由**: news.htmlだけが更新され、年表ページが取り残されて情報が古くなるため。基準を「数年後に振り返っても残る節目だけ」と厳しめに定義し、毎週必ず1件足す運用にならないようにした。
- **対象**: `.agents/skills/sync-news-html/SKILL.md`
- **commit**: `45ed9c9`

### 絞り込みの「クリア」ボタンを全ページから廃止
- **変更**: `generative.html` / `news.html` / `glossary.html` の絞り込みからクリアボタンを削除した。
- **理由**: 現在有効なボタンをもう一度押せば解除できるため、専用ボタンが余分だった。
- **対象**: `history/generative.html`, `history/news.html`, `history/glossary.html`
- **commit**: `052f07a`, `3e3133d`

### 生成AI年表の絞り込みを提供元の4種に整理
- **変更**: `generative.html` の絞り込みから「メディア生成」「技術」を外し、OpenAI / Anthropic / Google / オープンモデルの4種に絞った。
- **理由**: メディア生成・技術は該当カードが専用セクションにまとまっており、絞り込みとして機能していなかった。
- **対象**: `history/generative.html`
- **commit**: `7537011`

### 絞り込み時に目次バーの表示を追従させる
- **変更**: 絞り込みで非表示になったセクションを、上部の目次バーからも消すようにした。
- **理由**: 年表を絞り込んでいるのに目次バーが「技術革新」をハイライトするなど、タブと表示内容が食い違っていた。
- **対象**: `history/generative.html`
- **commit**: `85508f5`

### ナビの「生成AI詳細」を「生成AI年表」に改称
- **変更**: 全ページのナビ表記を統一した。
- **理由**: 「詳細」では何のページか分からず、実体が年表であることが伝わらなかった。
- **対象**: `history/` 配下の各HTML
- **commit**: `5d194ec`

### AI HISTORY のナビロゴのサイズを他ページに揃える
- **変更**: `index.html` のナビロゴのフォントサイズを他4ページと同じ値にした。
- **理由**: スマホで見たときにAI HISTORYだけロゴが小さく、意図しない差異になっていた。
- **対象**: `history/index.html`
- **commit**: `7b54849`

### 目次バーにスクロール連動のハイライトを追加
- **変更**: いま読んでいるセクションの項目を、ページのアクセント色（index=シアン、generative=マゼンタ）で点灯させ下線を引く。下線は `::after` の絶対配置なのでバーの高さは変わらない。スマホで項目がはみ出す幅では、現在地が隠れないようバー内を横スクロールして中央へ寄せる。`aria-current` も付与。あわせて、同時に2項目が光る問題、追従がカクつく問題、タップ直後に反映されない問題を修正した。
- **理由**: 長いページのどこを読んでいるのかが分からなかったため。
- **対象**: `history/index.html`, `history/generative.html`
- **commit**: `9629b88`, `5f5a84b`, `a697f36`, `362cae0`

### 音声タイトルの文字化けを修正
- **変更**: 2026-09-10 の音声タイトル「1万人の天才AIと数学적防衛線」の「적」（ハングルU+C801）を「的」に修正した。
- **理由**: NotebookLMが生成したアーティファクト名をそのまま取り込んでいるため、生成側で混入した文字が残っていた。全47件を走査し、想定外のスクリプト（ハングル・キリル・タイ文字）を含むのはこの1件のみと確認済み。
- **対象**: `history/audio-data.js`, `history/audio-titles.json`
- **commit**: `a4e888e`

### スマホでもセクション目次バーを表示する
- **変更**: スマホ幅で `display: none` にしていた `.section-bar` を、PCと同じくナビ直下にstickyで表示するようにした。`flex-wrap: nowrap` + `overflow-x: auto` で必ず1行に収め、`contain: layout` で内部幅が `document.scrollWidth` に算入されるのを防ぎ、iPhone幅(375px)では横スクロールなしで全項目が収まるようgap/padding/font-sizeを詰めた。あわせて、`body { overflow-x: hidden }` がbody自身をスクロールコンテナ化してstickyが効かなくなる問題を `overflow-x: clip` で解消した。
- **理由**: スマホでは下にスクロールしても目次が出ず、セクション間を移動する手段が無かった。
- **対象**: `history/index.html`, `history/generative.html`
- **commit**: `9da2882`, `2b72584`

### news.html の呼称を「最新トレンド」に統一
- **変更**: ナビや用語集のリンク表記を「最新ニュース」から「最新トレンド」に変更した。
- **理由**: このページはレポート25本から抽出した7テーマのダイジェストであり、日々のニュースを流すのは `daily.html` の役割。ナビで「デイリー」と並ぶと同じものの2つのリストに見えていた。`daily.html` と `generative.html` は既に「最新トレンド」と表記しており、残り3箇所を揃えた。
- **対象**: `history/index.html`, `history/glossary.html`, `docs/glossary.md`
- **commit**: `c608a16`

### PCナビを全ページで統一し、ページ内リンクを目次バーへ分離
- **変更**: ナビバーは別ページへの遷移リンクだけを持つようにし、行き先ごとに色を固定したピルで全ページ同じ並びにした。ロゴの `margin-right: auto` で右寄せすることで、検索ボックスの有無に関わらず並びが揃う。ページ内アンカーはナビから切り出し、ヒーロー下のsticky `.section-bar` に移した。ナビとバーの高さは実測して `--nav-h` / `--bar-h` に同期させ、`scroll-margin-top` が実際のヘッダー高に追従するようにした。あわせて、ナビ改修で失われた `news.html` の検索ボックスのスタイルを復旧し、幅を全ページ200pxに統一。用語集のナビは、そこへリンクしている `daily.html` / `news.html` を指すように変更した。
- **理由**: ページごとにナビの構成と配色がばらばらで、どこにいるのか・どこへ行けるのかが分かりにくかった。
- **対象**: `history/` 配下の全HTML
- **commit**: `7adb322`, `80539cc`, `f322d86`
