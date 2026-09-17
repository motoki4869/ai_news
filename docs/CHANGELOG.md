# CHANGELOG

ai_news の変更履歴。新しい日付を上に追記する。
記録対象は見た目・挙動が変わる変更のみ（内部リファクタ・日次の自動データコミットは含めない）。

---

## 2026-09-17

### 再生アイコンとクリック領域を拡大
- **変更**: 円なしの再生／停止ボタンについて、クリック領域を34pxから44pxへ、アイコンを17pxから22pxへ拡大した。
- **理由**: 円を廃止した後の再生アイコンが、10秒操作アイコンに比べて小さく見えていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### 再生ボタンの外側の円を廃止
- **変更**: 再生／停止ボタンの見た目から枠線と背景の円を外し、再生記号だけを表示するようにした。クリック領域は34pxのまま維持し、hover時は再生記号にだけ光を加える。
- **理由**: 円形矢印の10秒操作と再生ボタンの円が横一列に並び、補助操作と主操作の見た目が競合していたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### 10秒後送りアイコンの反転軸を修正
- **変更**: 10秒後送り側の矢印を、描画グループ自身ではなくSVG全体の中心を軸に反転するようにした。
- **理由**: 送り側だけ矢印と中央の「10」の位置関係がずれ、左右対称に見えなくなっていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### 10秒アイコンの矢印を細くし、数字の視認性を改善
- **変更**: 10秒送り／戻しアイコンの円弧を3pxから2pxへ細くし、矢印先端を小さくした。中央の「10」には背景色の縁取りを追加して、矢印と重なっても数字が潰れにくい表示にした。
- **理由**: 円形矢印への変更後、矢印の存在感が強く、中央の「10」の視認性を損なっていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `88bdcb1`

### 10秒送り／戻しを円形矢印アイコンへ変更
- **変更**: 10秒送り／戻しボタンを、文字入りピルから円形矢印と中央の「10」を組み合わせたインラインSVG表示へ変更した。送り側は矢印だけを左右反転し、「10」の向きとスクリーンリーダー用ラベルは維持した。
- **理由**: 再生ボタンに対する補助操作の見た目を整理し、一般的な音声プレイヤーで慣れた表記に合わせるため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`（今回の実装コミット）

### 10秒操作ボタンの枠線を弱める
- **変更**: 10秒送り／戻しボタンのシアン枠線の不透明度を0.35から0.20へ下げた。
- **理由**: 再生ボタンより補助操作が強く目立っていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`（今回の実装コミット）

### 音声プレイヤーの再生ボタンを縮小
- **変更**: 再生ボタンの直径を40pxから34pxへ変更した。
- **理由**: スマホ画面で再生ボタンだけが強く目立ち、音声パネル全体のバランスを崩していたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`（今回の実装コミット）

### スマホ幅で音声速度ボタンをNotebookLM音声の右側へ復元
- **変更**: 900px未満の音声パネルで、1倍・1.5倍・2倍の速度ボタンをNotebookLM音声ラベルと同じ行の右端へ配置した。説明文の長さで横にはみ出さないよう、説明文側のグリッド項目を縮小可能にした。
- **理由**: 直前の音声パネル再配置で速度ボタンが説明文の下段左へ移動し、スマホでNotebookLM音声ラベルとの対応が分かりにくくなっていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`（今回の実装コミット）

### iPad・PC幅で音声プレイヤーの余白を詰め、速度と「視聴済み」を右上へ移動
- **変更**: 900px以上での音声パネルを2列のグリッドに組み直した。左列にキッカー・タイトル・説明文、右列の上段に速度ボタン（1倍/1.5倍/2倍）と「視聴済み」、下段にプレイヤーを置く。狭い画面（900px未満）の並びは変えていない。合わせて `.audio-kicker-row` / `.audio-label-row` の入れ子をやめ、速度と「視聴済み」を `.audio-actions` にまとめた（狭い画面では `display: contents` で升目に直接並べる）。「視聴済み」の絶対配置による位置合わせも廃止した。
- **理由**: iPad幅では右半分がプレイヤー1行だけなのに左半分は文字が3行あり、右上に大きな余白が空いて間延びして見えていた。速度ボタンが左下、「視聴済み」が右下と操作系が離れていたのも、視線が散る原因になっていた。
- **対象**: `history/daily.html`
- **確認**: 1024pxでパネルの高さが144px→127pxに縮み、速度ボタンと「視聴済み」がプレイヤーの真上に並ぶこと、両者がキッカー・プレイヤーと重ならないこと（プレイヤーとの間隔16px）を実測。390px・430pxではキッカー行の「視聴済み」、説明文下の速度ボタン、プレイヤー2行の位置が変更前と1pxも変わらないことを座標で確認。744／768／820／899px（プレイヤーが折り返す帯）と940／1280／1440pxでも横はみ出し0。速度切替（`playbackRate` 1→2→1）と「視聴済み」の保存（`ai_news.audio_heard_dates`）が動作し、コンソールエラー0件。`node --test test/*.js` は27件中26件成功（残る1件 `scroll-margin-top` は本変更前から失敗している別件）。

### Codexフォールバックが定時実行から起動できなかったのを修正
- **変更**: `scripts/lib/codex_fallback.sh` の `run_codex_fallback()` で、`codex` と `node` の実行ファイルを明示的にフルパス解決するようにした。`CODEX_BIN` / `NODE_BIN` 環境変数があればそれを使い、無ければ `command -v` → `/opt/homebrew/bin` → `/usr/local/bin` の順に探す。見つからない場合は理由を標準エラーに出して終了コード127を返す。起動時は `node` のあるディレクトリを `PATH` の先頭に足す。
- **理由**: launchdは `.zshrc` を読まず `PATH` が `/usr/bin:/bin:/usr/sbin:/sbin` に限られる。`codex` の実体は `/opt/homebrew/bin` にあるため、PATH頼りの呼び出しは `codex: command not found`（終了コード127）になっていた。さらに `/opt/homebrew/bin/codex` は `#!/usr/bin/env node` のNodeスクリプトなので、`codex` のパスを解決しただけでは `env: node: No such file or directory` で落ちる。呼び出し元が `claude` / `gh` / `python3` を明示解決しているのに `codex` だけ漏れていた。Claude利用上限に到達した朝は、フォールバックが起動せずニュース更新が丸ごと失われる状態だった（`logs/daily_news.log` に上限到達の記録は0件で、これまで発覚していなかった）。
- **対象**: `scripts/lib/codex_fallback.sh`
- **確認**: `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=$HOME`（launchd相当）で `run_codex_fallback` を実行し、修正前は `env: node: No such file or directory`（127）だったのが、修正後は `codex exec` が終了コード0で完走し応答を返すことを確認（ChatGPTログインも同環境で通ることを実地確認）。

### 日次ログの音声プレイヤーを自作のものに置き換え
- **変更**: `daily.html` の音声再生を、ブラウザ標準の `<audio controls>` からサイトの配色に合わせた自作プレイヤーに差し替えた。再生／一時停止ボタン、シークバー（読み込み済み範囲と再生済み範囲を色分け）、現在位置と長さの表示を自前で描画する。既存の10秒送り／戻しボタンはシークバーの下の1行にまとめ、900px以上では操作ボタンを左・シークバーを右に並べた1行組みにする。音を鳴らす仕組みは従来どおり `<audio>` のままで、要素は画面外に置いて残している。
- **理由**: 標準のコントロールはブラウザごとに見た目が違い（Safariは黒い角丸バー、Chromeは灰色のバー）、CSSも当てられないため、左右の自作ボタンだけがサイトの配色で中央の再生バーだけが浮いていた。標準プレイヤーが最小幅を主張するせいで狭い画面のレイアウトが崩れやすい問題もあった。
- **対象**: `history/daily.html`、`history/audio-player.js`（新規）、`test/test_audio_player.js`（新規）
- **確認**: 再生・一時停止・10秒送り／戻し・シークのドラッグ・矢印キー（1回＝1秒）・速度切替（1／1.5／2倍）が動作すること、日付を切り替えると再生位置と長さの表示が0に戻ること、長さが確定するまでシークバーが無効なこと、スマホ幅390pxで横はみ出しが0であること、900px以上で「視聴済み」の絶対配置がプレイヤーに重ならないこと（速度ボタン行との中心ずれ1px）を実ブラウザで確認。`node --test test/*.js` は27件中26件成功（残る1件 `scroll-margin-top` は本変更前から失敗している別件）。

### 朝のmacOS通知が出ない日があったのを修正
- **変更**: `daily_news.sh` のmacOS通知を `notify()` 関数にまとめ、本文をAppleScriptのソースへ文字列として埋め込むのをやめて引数（`on run argv`）で渡すようにした。長さの切り詰めもAppleScript側の `text 1 thru 200` に移し、シェル側の `cut -c1-200` とエスケープ用の `sed` を廃止した。
- **理由**: launchdはロケールを渡さないためCロケールで動き、`cut -c` が文字ではなくバイトを数える。日本語は1文字3バイトなので200バイト目が文字の途中に当たると壊れたUTF-8ができ、`osascript` が `syntax error: "\"" があるべきところですがunknown tokenが見つかりました (-2741)` で落ちて通知が出なかった。`logs/daily_news.err.log` に32回記録されていた。ニュース更新とpush自体は成功していたため、症状は「朝の通知だけが出ない日がある」だった。
- **対象**: `scripts/daily_news.sh`
- **確認**: `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`（launchd相当）で、修正前は9/17の実際の要約が `133:134: syntax error` を再現し、ログの記録と一致することを確認。修正後は同じ要約・Codexフォールバック経路・引用符やバックスラッシュを含む文・失敗通知の4経路すべてが終了コード0で通知された。200文字超の文字列が文字単位（バイト単位ではなく）で200文字＋`…`に切り詰められることも確認。
- **commit**: `HEAD`（今回の実装コミット）

### 使われなくなった旧レポートデータを削除
- **変更**: `history/reports-data.js`（816KB）をリポジトリから削除した。ローカルには `_deleted/history/reports-data.js` として退避してある。
- **理由**: レポート全文を1本ずつ `history/reports/<ID>.json` から取りに行く方式へ変えた結果、このファイルは生成もされず、どのページからも読まれない状態になった。残しておくと「まだ使われている」と誤解する元になる。
- **対象**: `history/reports-data.js`
- **commit**: `HEAD`（今回の実装コミット）

### レポート全文をタップした分だけ取りに行くようにした
- **変更**: 全レポートのHTMLを1ファイルにまとめていた `history/reports-data.js` をやめ、`scripts/generate_reports_data.py` がレポート1本につき `history/reports/<ID>.json` を1ファイル出すようにした。`news.html` / `archive.html` が最初に読むのはレポート名→IDの対応表 `history/reports-index.js`（gzip 1.0KB）だけで、全文はカードをタップした時点で `fetch` する。初回表示のデータ転送量は gzip 281.8KB → 1.0KB に減り、代わりに1タップあたり平均12.7KBを取得する（取得済みのものはページ内に保持して再取得しない）。読み込み中は「読み込み中…」を、取得に失敗した場合は再試行を促す文言を表示する。
- **理由**: 25本ぶんの全文（生816KB）をページを開いた瞬間に全部ダウンロードしていたが、実際に読まれるのはタップした1〜2本だけで、残りは毎回捨てていた。NEWS FEEDと過去ログは1ページあたりカード42枚あり、全部を先読みする理由がない。
- **対象**: `scripts/generate_reports_data.py`, `history/report-modal.js`, `history/news.html`, `history/archive.html`, `history/reports-index.js`, `history/reports/*.json`, `.agents/skills/sync-news-html/SKILL.md`, `README.md`
- **確認**: キャッシュ無効のローカルサーバーで `news.html` / `archive.html` の両方について、初回表示で `reports/` へのリクエストが0件であること、タップで該当1本だけを取得して本文・表・KaTeX数式が旧データと同一に描画されること、複数レポートを持つカードが2本を区切り線付きで並べること、2回目以降は再取得しないこと、開閉5回で `history.length` が一定であること、戻る／進むが従来どおり動くこと、取得失敗時にエラー文言が出てから開き直すと再取得されること、読み込み中に閉じた／別カードを開いた場合に古い結果が後から割り込まないことを確認。生成データが旧 `reports-data.js` と全25本バイト一致することも照合した。
- **commit**: `HEAD`（今回の実装コミット）

### レポートのモーダルを「戻る」で閉じられるようにした
- **変更**: `news.html` / `archive.html` のレポート全文モーダルを開くときに `history.pushState` で履歴を1段積み、`popstate` で閉じるようにした。×ボタン・背景タップ・Escは `history.back()` を経由して同じ経路に合流する。「進む」で開き直せるよう、履歴のstateに表示中のレポート名を持たせた。
- **理由**: モーダルの開閉がDOM属性の切り替えだけで履歴に現れず、スマホで端からスワイプして閉じようとすると、閉じるどころか `news.html` に来る前のページへ戻ってサイトから離脱していた。閉じる手段が×ボタンと背景タップしか無かった。
- **対象**: `history/report-modal.js`
- **確認**: ローカルで×ボタン5回開閉しても `history.length` が一定であること（履歴が積み上がらないこと）、戻る操作でページに留まったままモーダルだけ閉じること、進むで開き直ること、Esc・背景タップ・閉じた状態からのさらなる戻り（正しく離脱）を `news.html` / `archive.html` の両方で確認。
- **commit**: `HEAD`（今回の実装コミット）

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
