# CHANGELOG

ai_news の変更履歴。新しい日付を上に追記する。
記録対象は見た目・挙動が変わる変更のみ（内部リファクタ・日次の自動データコミットは含めない）。

---

## 2026-09-21

### 用語集のトレンド表記短縮
- **変更**: 用語集上部ナビと末尾CTAの「最新トレンド」を「トレンド」に変更した。
- **理由**: AI HISTORY側のナビ表記と揃え、スマホ幅でも短い導線名で表示するため。
- **対象**: `history/glossary.html`、`test/test_glossary_navigation.js`
- **commit**: `HEAD`

### AI HISTORYナビのトレンド表記短縮
- **変更**: AI HISTORY上部ナビの「最新トレンド」を「トレンド」に変更した。
- **理由**: スマホ幅でナビリンクを1行に収めやすくし、各リンクを素早く判別できるようにするため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### AI HISTORYナビの生成AI年表表記短縮
- **変更**: AI HISTORY上部ナビの「生成AI年表」を「AI年表」に変更した。
- **理由**: スマホ幅でもリンクを1行に収めやすくし、ナビ全体の視認性を高めるため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### AI比較モーダルの見出し更新
- **変更**: AI比較モーダルの見出しを「最新AIの性能を比較する」に変更した。
- **理由**: 最新AIの性能を確認する導線だと、ポップアップ上で自然に伝わるようにするため。
- **対象**: `history/index.html`、`history/generative.html`、`test/test_index_benchmark_modal.js`
- **commit**: `HEAD`

### Arena.aiの説明文調整
- **変更**: Arena.aiの説明を「人間の投票による実用性・人気の比較」に変更した。
- **理由**: 比較対象の特徴を、より自然で正確な表現にするため。
- **対象**: `history/index.html`、`history/generative.html`、`test/test_index_benchmark_modal.js`
- **commit**: `HEAD`

### 生成AI年表の戻りリンク位置調整
- **変更**: 生成AI年表上部ナビの「← AI HISTORY」をAI比較ボタンの右側へ移動した。
- **理由**: 年表から比較サイトを開く導線を先に置き、全体年表への戻り先をナビ右側に整理するため。
- **対象**: `history/generative.html`、`test/test_index_benchmark_modal.js`
- **commit**: `HEAD`

### 生成AI年表へのAI比較モーダル追加
- **変更**: `GENERATIVE ERA`ページの上部ナビにも「AI比較」ボタンと、Arena.ai・Artificial Analysisを選べるモーダルを追加した。
- **理由**: 生成AI年表を読んでいる途中からも、モデル性能の比較サイトへ移動できるようにするため。
- **対象**: `history/generative.html`、`test/test_index_benchmark_modal.js`
- **commit**: `HEAD`

### AI性能比較リンクの選択モーダル化
- **変更**: AI HISTORY上部の「AI比較」ボタンから、Arena.aiとArtificial Analysisを選べるモーダルを表示するようにした。外部リンクは新しいタブで開き、閉じるボタン・背景クリック・Escapeキーに対応した。
- **理由**: 性能比較サイトを1つに限定せず、目的に応じて選べるようにするため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`、`test/test_index_benchmark_modal.js`
- **commit**: `HEAD`

### AI Arenaへのナビゲーション追加
- **変更**: AI HISTORY上部のナビに、文章・画像などのAIモデル比較ランキングへ移動できる「AI Arena」リンクを追加した。
- **理由**: 分野別のAI性能比較を、AI HISTORYからすぐ確認できるようにするため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### デイリーニュースをもとに用語集へ18語を追加
- **変更**: `everyday_news/*.md`のデイリーニュースを精査し、未収録だった18語（Claude Tag、Terminal-Bench / Terminal-Bench-Science、Artificial Analysis Intelligence Index、DeepSWE、Deep Think、Jalapeño、主権AI / ソブリンAI、FDE、RVG、WAICO、パックス・シリカ、SB 53、ZDR、DSA / VLOSE、EU KIDS Act、CyberGym、HEIR / FHE）を`docs/glossary.md`に追加し、既存のOpenAI行にGPT-Liveを追記した。`history/glossary-data.js`を再生成し、`term-link.js`による自動リンク機構を通じてデイリー側からもこれらの用語へのリンクが有効になった。
- **理由**: ユーザーからの依頼で、デイリーニュースに登場するが用語集に未収録の語を洗い出して追加する必要があったため。
- **対象**: `docs/glossary.md`、`history/glossary-data.js`
- **commit**: `HEAD`

### Claude Code再レビューの重要指摘修正（フック通知）
- **変更**: Claude/CodexのLINE通知フックでもHEAD上の当日見出しを確認し、commit前の作業ツリーから通知しないようにした。未commit時のフック抑止テストを追加し、再送テストのclaim・日付・一時リポジトリを分離した。フックだけ短い送信timeoutを使い、日次本体の送信retry余裕は維持した。
- **理由**: Claude Code再レビューで、Write/Edit直後のPostToolUseフックが日次処理のcommit・push前にLINE通知を送る経路が残っており、日次スクリプト側のHEAD確認だけでは未公開ニュースを通知し得ることが判明したため。
- **対象**: `.claude/hooks/line_notify.sh`、`.codex/hooks/line_notify.sh`、`scripts/lib/codex_fallback.sh`、`scripts/lib/test_line_notification_dedupe.sh`、`test/test_daily_news.sh`
- **commit**: `HEAD`

### Claude Code再レビューの重要指摘修正
- **変更**: 週次leaseのrefresh失敗時に編集・commit・pushを中止する手順を追加した。日次LINE通知は作業ツリーではなくHEADにcommit済みの当日見出しを確認してから送るようにし、Codexフックの設定ファイル参照先とLINE送信のタイムアウトを修正した。未commit状態の通知抑止と同一日再送の回帰テストも追加した。
- **理由**: Claude Code再レビューで、lease回収後も週次処理が編集を続ける経路、未pushのニュースをLINE通知する経路、Codexフックが存在しない設定ファイルを参照する問題、フックの送信待ちが長くclaim解放を阻害する問題が判明したため。
- **対象**: `.agents/skills/sync-news-html/SKILL.md`、`.codex/hooks/line_notify.sh`、`scripts/daily_news.sh`、`scripts/lib/codex_fallback.sh`、`scripts/lib/test_line_notification_dedupe.sh`、`test/test_daily_news.sh`
- **commit**: `HEAD`

### Claude Code再レビュー指摘の追加修正（第2回）
- **変更**: 週次leaseの取得時に出力されたtokenを固定して扱い、stale回収後のrefresh競合を再判定するようにした。LINEフックを共通送信処理へ統一し、送信失敗時のclaim解放とcurlのtimeout・再試行を追加した。日次commit対象を全`everyday_news/*.md`へ明示し、日付に依存しない回帰テストと、通知条件を音声HEADの状態から分離した。
- **理由**: Claude Code再レビューで、週次leaseが別実行のtokenを解放する競合、stale回収とrefreshの競合、フック経由の送信失敗時に再送できない経路、過去月の原本変更がcommit対象から漏れる経路、テストの日付固定、音声状態による通知抑止が判明したため。
- **対象**: `scripts/lib/news_update_lock.sh`、`.agents/skills/sync-news-html/SKILL.md`、`.claude/hooks/line_notify.sh`、`.codex/hooks/line_notify.sh`、`scripts/lib/codex_fallback.sh`、`scripts/daily_news.sh`、`scripts/daily_news_prompt*.txt`、`test/`、`docs/CHANGELOG.md`
- **commit**: `HEAD`

### Claude Code再レビュー指摘の追加修正
- **変更**: ロックのstale回収をtoken照合付きの原子的renameに変更し、owner不在ロックの期限回収、週次leaseトークンのファイル経由受け渡し、9章モデル表の必須セル検証を追加した。LINE送信失敗時のclaim解放と再送、当日分がない場合の通知抑止、失敗時音声commitの対象限定、明示的な日次commit対象、失敗理由の表示、stale残骸のgitignoreも追加した。
- **理由**: 再レビューで、ロック回収のTOCTOU、owner欠落による恒久停止、週次leaseの解放失敗、空のモデル名公開、LINE送信失敗の再送不能、無関係な変更の音声commit混入、通知対象の誤送信が判明したため。
- **対象**: `scripts/lib/news_update_lock.sh`、`scripts/daily_news.sh`、`scripts/lib/line_notification_dedupe.sh`、`scripts/lib/codex_fallback.sh`、`scripts/generate_glossary_data.py`、`.agents/skills/sync-news-html/SKILL.md`、`.gitignore`、`scripts/daily_news_prompt*.txt`、`test/`
- **commit**: `HEAD`

### 日次・週次ニュース更新の再実行通知とロック処理の修正
- **変更**: Claude Codeレビューで見つかった週次エージェント向けleaseロック、所有者確認付きのstale回収、同日再実行時のLINE通知claim、commit済みニュースに対する音声再試行、変更なしcommitの正常扱い、SUMMARY原因通知、用語集の正式名称空欄ルール、生成物パーミッション維持、テストの一時リポジトリ隔離を追加した。
- **理由**: 失敗後の再実行でサイト更新・LINE通知・音声生成の一部だけが欠落する経路と、日次・週次のロックがプロセス寿命やPIDだけに依存して競合する経路をなくすため。
- **対象**: `scripts/daily_news.sh`、`scripts/lib/news_update_lock.sh`、`scripts/daily_news_prompt.txt`、`scripts/daily_news_prompt.codex.txt`、`scripts/generate_glossary_data.py`、`.agents/skills/sync-news-html/SKILL.md`、`test/`
- **commit**: `HEAD`

### 日次・週次ニュース更新の失敗復旧と競合対策
- **変更**: 日次更新の成功・失敗Summaryを機械判定可能な形式に統一し、生成失敗や成功Summary欠落を成功通知しないようにした。当日分が既に存在する場合も生成・commit処理を続行し、失敗後の同日再実行で復旧できるようにした。用語集生成器に表の見出し・列数・必須セルの検証と原子的な生成物置換を追加し、日次・週次更新で共有するリポジトリロックと回帰テストを追加した。日々陳腐化する用語集の日数・最終更新メタデータは削除した。
- **理由**: solレビューで、失敗時の成功扱い、同日再実行のスキップ、壊れた用語行の黙った取りこぼし、生成物の非アトミック更新、テスト不足、日次・週次の同時実行によるGit index競合が判明したため。
- **対象**: `scripts/daily_news.sh`、`scripts/lib/news_update_lock.sh`、`scripts/generate_glossary_data.py`、`scripts/daily_news_prompt.txt`、`scripts/daily_news_prompt.codex.txt`、`.agents/skills/sync-news-html/SKILL.md`、`docs/glossary.md`、`.gitignore`、`test/`
- **commit**: `HEAD`

### 日次ニュース更新時の用語集確認・再生成
- **変更**: 日次ニュース生成用のClaude版・Codex版プロンプトに、当日追加したニュースから未収録用語を確認し、必要に応じて`docs/glossary.md`へ追加したうえで`history/glossary-data.js`を再生成する手順を追加した。用語集関連ファイルを日次コミットの対象にも含めた。
- **理由**: 日次ニュースに登場した新しいAI用語が、週次レポート更新まで用語集へ反映されない期間をなくすため。
- **対象**: `scripts/daily_news_prompt.txt`、`scripts/daily_news_prompt.codex.txt`、`docs/glossary.md`、`test/test_daily_prompt_glossary.js`
- **commit**: `HEAD`

### 用語集掲載語の本文リンク化を全用語へ拡張
- **変更**: `term-link.js`が用語欄の括弧内・スラッシュ区切りの別名、日本語用語、2文字の略語を含む全用語を候補にし、1つの本文要素内にある複数の用語をすべて`glossary.html`へのリンクへ変換するようにした。ニュース・レポート全文・デイリーで共通利用されるため、`DI（意思決定知能）`の`DI`もリンク化される。回帰テストを追加した。
- **理由**: 用語集に登録済みの`DI`が最新トレンドの記事本文でリンク化されず、同じ問題がデイリーにも起きうる状態だったため。
- **対象**: `history/term-link.js`、`test/test_term_link.js`
- **commit**: `HEAD`

### 全レポートの章立て番号を統一
- **変更**: `report/`配下の全レポートで、H2/H3/H4の見出しをそれぞれ`1.`、`1.1`、`1.1.1`形式の連番に統一し、生成済みのレポートJSONも更新した。週次更新用の`sync-news-html`スキルに、章立てが欠けている場合は本文を先に補正する手順を追加した。
- **理由**: レポートによって章番号や節番号が欠けており、目次上で章の階層と順序を把握しにくかったため。
- **対象**: `report/*.md`、`history/reports/*.json`、`.agents/skills/sync-news-html/SKILL.md`、`test/test_report_headings.js`
- **commit**: `HEAD`

### iPad・デスクトップの章一覧幅と角丸を調整
- **変更**: iPad・デスクトップの章一覧ドロワー幅を`80%`（最大`640px`）に広げ、右側の上下の角を`16px`丸めた。スマホの下部シートは既存の角丸を維持する。
- **理由**: 章の内容をより長く1行で把握できる幅を試し、ドロワーと本文の境界を柔らかく見せるため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### iPad・デスクトップの章一覧を拡張
- **変更**: iPad・デスクトップの章一覧ドロワー幅を`70%`（最大`560px`）に広げ、右端の水色の境界線を削除した。スマホの下部シートは従来どおり維持する。
- **理由**: 章タイトルが固定幅で折り返され、1行で内容を把握しにくかったため。右端の境界線も目次の区切りを強く見せていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### 章一覧の最上位項目を見出しに左揃え
- **変更**: 「まず押さえる3点」と章見出しの目次項目を、目次タイトル「章から読む」の文字位置に揃え、下位見出しだけ`10px`右へインデントするようにした。
- **理由**: 目次項目の矢印が「章から読む」より右にずれており、左側の余白がまだ広く見えていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### 章一覧の左余白と階層インデントを調整
- **変更**: スマホの章一覧シートの左右パディングを詰め、章見出しのインデントを`10px / 20px`に調整した。
- **理由**: 章一覧を開いたとき、左端から目次項目までの距離が大きく、右側より左側の余白が目立っていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### 「まず押さえる3点」の目次階層を1章に統一
- **変更**: 目次の要約項目に、同じレポートの最初の章見出しと同じ階層クラスを付与するようにした。
- **理由**: 「まず押さえる3点」だけが章1より浅く表示され、目次の階層関係が分かりにくく見えていたため。
- **対象**: `history/report-modal.js`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### 「まず押さえる3点」を章目次から選べるように
- **変更**: レポート全文モーダルの目次の先頭に「まず押さえる3点」を追加し、選択すると要約位置へスムーススクロールするようにした。要約が生成されるレポートだけ表示する。
- **理由**: 章だけでなく、レポート冒頭の要点にも目次からすぐ戻れるようにするため。
- **対象**: `history/report-modal.js`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### スマホ版の章一覧シートの上余白を縮小
- **変更**: モバイルの章一覧シートの最大高さを`calc(100% - 24px)`に広げ、内容量が多いときも上端に残る余白を24pxまで抑えた。
- **理由**: 章一覧を開いたとき、シートがモーダルの76%に制限され、章項目の上に大きな空白が残っていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### スマホ版の読了目安を横並び表示に統一
- **変更**: モバイル幅でも「レポートを読む前に」と読了目安を同じ行に表示するようにした。最新トレンドと過去ログで共通化した。
- **理由**: iPad・デスクトップでは横並びなのに、スマホだけ縦積みになって表示領域を余計に使っていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### レポート導入部の余白と区切り線を調整
- **変更**: 章一覧ボタンと「レポートを読む前に」の間に12pxの余白を追加し、3つの要点の直下にある点線を削除した。
- **理由**: 導入部の操作ボタンと説明が詰まって見え、要点の下の点線が本文との境界として強く見えていたため。
- **対象**: `history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### レポート要点の省略表示を廃止
- **変更**: 3つの要点を文字数・行数で切り詰めず、全文を折り返して表示するようにした。要点内の省略記号も廃止した。
- **理由**: 要点の末尾が画面上で切れており、内容を確認するには本文を探し直す必要があったため。
- **対象**: `history/report-modal.js`、`history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### レポート要約を3つの要点表示に変更、章目次を左ドロワー化
- **変更**: レポート冒頭の要約を複数段落の連結表示から、本文の冒頭文を意味単位で抽出した3つの箇条書きへ変更した。あわせて、左上の「章一覧」ボタンに合わせて目次ドロワーを左側から開く配置とアニメーションへ変更した。スマホでは下部シート表示を維持する。
- **理由**: 連結された冒頭文は要約として要点を把握しにくく、左上の操作ボタンと右側に開く目次の方向が一致していなかったため。
- **対象**: \`history/report-modal.js\`、\`history/news.html\`、\`history/archive.html\`、\`test/test_report_modal_preload.js\`
- **commit**: \`HEAD\`

### レポート全文の章目次を開閉式ドロワーへ変更
- **変更**: レポート全文モーダルの章目次を本文上の常時表示からヘッダーの「章一覧」ボタンへ移し、クリック時だけ表示するデスクトップ右側ドロワー／スマホ下部シートに変更した。章を選ぶと該当見出しへ移動して目次を閉じ、背景クリック・閉じるボタン・Escキーでも閉じられるようにした。概要と読了目安は本文冒頭に残し、目次のないレポートではボタン自体を隠す。
- **理由**: 章目次が本文の上部を大きく占有し、レポートを読み始めるときに本文が見えにくくなっていたため。必要なときだけ目次を呼び出せる構成にして、本文の視認性と章移動の両立を図るため。
- **対象**: \`history/report-modal.js\`、\`history/news.html\`、\`history/archive.html\`、\`test/test_report_modal_preload.js\`
- **commit**: \`HEAD\`

### レポート全文に概要・章目次・読了目安を追加
- **変更**: `news.html` と `archive.html` のレポート全文モーダルに、本文冒頭を3行に収めた概要、見出しから生成した章目次、本文文字数から算出する読了目安を追加した。章目次はモーダル内で該当見出しへスムーススクロールする。
- **理由**: 長いレポートを最初から最後までスクロールしなくても、内容の全体像と必要な章を先に把握できるようにするため。
- **対象**: `history/report-modal.js`、`history/news.html`、`history/archive.html`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### レポート全文モーダル内の用語からも用語集へジャンプできるように
- **変更**: `history/term-link.js`の`linkifyGlossaryTerms(root, selector)`に対象範囲を指定できる第2引数を追加し、`history/report-modal.js`のレポート全文描画（`paint()`）から`.rpt-section p, .rpt-section li, .rpt-section td`を対象に呼び出すようにした。これにより、`news.html`（最新トレンド）・`archive.html`（過去ログ）でニュースカードをタップして開く全文レポートの本文中に登場するMCP・RSI等の用語も、直下の要約カードと同じくバイオレットの下線リンクとして用語集へジャンプできるようになった。
- **理由**: ユーザーから「デイリーや最新トレンドのレポートの中からも遷移できるようにできない？」との要望があったため。要約カード本文は既に対応済みだったが、カードをタップして開く元レポートの全文には未反映だった（`daily.html`はカードをタップしても外部の出典記事へのリンクしか持たず内部の全文表示機能自体が無いため、対象は`news.html`/`archive.html`のレポート全文モーダルのみとなる）。
- **対象**: `history/term-link.js`, `history/report-modal.js`
- **確認**: ローカルサーバー起動後、cmux browserでnews.html/archive.htmlのカードをタップしてレポート全文モーダルを開き、本文中の用語（RSI等）がリンク化されていること、クリックで`glossary.html?q=RSI`へ正しく遷移し、モーダルを閉じる操作と競合しないことを確認した。
- **commit**: `HEAD`

### 用語集の検索状態をURLに反映、記事本文の用語から直接ジャンプできるように
- **変更**: `history/glossary.html`の検索ボックスの入力値を`?q=`パラメータとしてURLに同期（`history.replaceState`）し、`glossary.html?q=MCP`のようなURLを直接開くと検索欄が自動入力され、絞り込んだ上で最初に一致した用語カードまでスクロールしてバイオレットの光るアニメーション（`.jump-flash`）で強調表示するようにした。あわせて新規ファイル`history/term-link.js`を追加し、`news.html`・`archive.html`・`daily.html`のニュースカード本文中に登場する用語集掲載済みの英字略語・製品名（MCP、RAG、OpenClaw等）を自動検出し、1カードにつき最初の1語だけを`glossary.html?q=<用語>`への内部リンクに変換する。news.html/archive.htmlのカードは全体がタップで全文モーダルを開く仕様のため、リンククリックがモーダル表示に伝播しないよう`stopPropagation`を追加した。daily.htmlは日付切り替えのたびにカードを再描画するため、`renderDay()`内で毎回リンク化を呼び直す形にした。
- **理由**: レビュー指摘「用語集でMCPを検索できるが、検索状態がURLに反映されない。記事中の『MCP』から該当用語へ移動できると理解が途切れない」に対応するため。
- **対象**: `history/glossary.html`, `history/news.html`, `history/archive.html`, `history/daily.html`, `history/term-link.js`（新規）
- **確認**: ローカルサーバー起動後、cmux browserで`glossary.html?q=RHI`への直接遷移・強調表示、news.html/archive.html/daily.html各ページでの用語リンクの表示とクリック動作、およびnews.html/archive.htmlでリンククリック時に全文モーダルが誤って開かないことを確認した。
- **commit**: `HEAD`

### AI DAILY LOGにその日の見出し一覧を追加、音声プレイヤーとの順序を調整
- **変更**: `history/daily.html`の日別コンテンツに、その日のニュースカードの見出しを番号付きで並べた目次（`.headline-list`）を追加した。各見出しをクリックすると、対応するニュースカードの位置まで固定ナビの下にスムーススクロールする。カードには`daily-card-<index>`のIDと`scroll-margin-top`を付与し、ジャンプ先が固定ナビに隠れないようにした。日によって件数（3〜9件）が変わるため上限は設けず、実データの件数だけ表示する。表示順は「日付ヘッダー→音声プレイヤー→見出し一覧→カード一覧」とした（初期実装では見出し一覧を音声プレイヤーより上に置いていたが、ユーザーの指摘で入れ替えた）。
- **理由**: 各カードの説明が丁寧な分、全体を把握するには縦に長くスクロールする必要があり、その日にどんな話題があったか一目で分からなかったため。
- **対象**: `history/daily.html`
- **確認**: ローカルサーバー起動後、cmux browserでPC幅・モバイル幅（390×844）の両方で表示順・見出し一覧のクリックによるジャンプ動作を確認した。
- **commit**: `HEAD`

### 読者向けページの内部パス表記を自然な文言に修正
- **変更**: `history/archive.html`（meta description・hero見出し・footer）、`history/news.html`（hero内source-note・footer）、`history/glossary.html`（hero内source-note・footer）、`history/daily.html`（footer）から、`ai_news/report`・`docs/glossary.md`・`ai_news/everyday_news`・「news.htmlから循環した」といった内部のリポジトリ構成・ファイルパスの直書きを削除し、「過去に掲載したトレンド」「参考レポート」「掲載用語」のような読者向けの自然な言い回しに書き換えた。
- **理由**: サイト訪問者には文脈のない内部のディレクトリ・ファイル名がそのまま表示されており、実装の都合が透けて見える表記になっていたため。
- **対象**: `history/archive.html`, `history/news.html`, `history/glossary.html`, `history/daily.html`
- **commit**: `HEAD`

### 全文表示モーダルのキーボード操作を修正
- **変更**: `history/report-modal.js`にフォーカス管理を追加した。モーダルを開くと開く前にフォーカスしていた要素（タップしたカード）を記憶し、閉じるボタンへフォーカスを移す。開いている間はTabキーがモーダル内のfocusable要素だけを巡回する（フォーカストラップ）ようにし、背後のニュースカード列へ抜けないようにした。閉じたときは記憶しておいた元のカードへフォーカスを戻す。
- **理由**: レポートを開いてもフォーカスが背後のカードに残ったままで、Tabキーで背後の次のカードへ移動してしまっていたため。
- **対象**: `history/report-modal.js`
- **commit**: `HEAD`

## 2026-09-20

### 過去ログページにもスクロール追従の目次を追加
- **変更**: `history/archive.html`に、最新トレンド・AI HISTORY・用語集と同様のスクロール追従の目次（`.section-bar`）を追加した。7テーマは既存の`.quick-filters`ボタンと同じ静的HTMLで、アンカーリンクをそのままハードコードした（news.htmlの実装と同じ構成。archive.htmlにはティッカーが無いため`top`は`var(--nav-h)`のみ）。section-spyによる現在地ハイライト、絞り込みで非表示になったセクションのリンク無効化も同様に実装。既存のQUICK FILTERボタンによる絞り込みはそのまま維持し、両方を併存させた。
- **理由**: ユーザーから「過去ログも同様にお願い」との依頼があったため。
- **対象**: `history/archive.html`
- **commit**: `HEAD`

### 用語集ページにもスクロール追従の目次を追加
- **変更**: `history/glossary.html`に、最新トレンド・AI HISTORYと同様のスクロール追従の目次（`.section-bar`）を追加した。9カテゴリはJSでデータ（`window.GLOSSARY`）から動的生成しているため、目次のリンクも生成ループ内でカテゴリタイトルをそのまま使って動的に作る形にした。section-spyによる現在地ハイライト、絞り込みで非表示になったカテゴリのリンク無効化も同様に実装。既存のCATEGORY絞り込みボタン（クリックでフィルター＋該当セクションへスクロール）はそのまま維持し、両方を併存させた。
- **理由**: ユーザーから「用語集も同様にお願い」との依頼があったため。
- **対象**: `history/glossary.html`
- **commit**: `HEAD`

### 最新トレンドページにスクロール追従の目次を追加
- **変更**: `history/news.html`にAI HISTORYページと同様の、スクロールすると上部に貼り付く目次（`.section-bar`、7テーマへのアンカーリンク）を追加した。現在表示中のセクションに応じてリンクがハイライトされる（section-spy）機能も実装し、フィルターで非表示になったセクションのリンクは無効化される。既存のヒーロー内クイックフィルター機能はそのまま維持し、両方が併存する構成にした。
- **理由**: ユーザーから「AI HISTORYのページ同様、下にスクロールした時に上に目次が出るようにしてほしい」との依頼があったため。従来はヒーロー内のクイックフィルターがナビゲーションを兼ねる設計だったが、フィルターはスクロールで流れてしまいスティッキーではなかった。
- **対象**: `history/news.html`
- **commit**: `HEAD`

## 2026-09-18

### 用語集の上下ナビ順をAI HISTORYに統一
- **変更**: 用語集の上部ナビと末尾CTAで、最新トレンドをデイリーより先に配置した。
- **理由**: AI HISTORYのページ順（最新トレンド → デイリー）と揃えるため。
- **対象**: `history/glossary.html`、`test/test_glossary_navigation.js`
- **commit**: `HEAD`

### 用語集末尾の遷移順と矢印方向を整理
- **変更**: 用語集末尾のリンクを「← AI HISTORY 全体年表」「デイリーログ →」「最新トレンド →」の順に変更した。
- **理由**: 全体年表へ戻る導線を左側に置き、他の関連ページへの遷移を右向きに統一するため。
- **対象**: `history/glossary.html`、`test/test_glossary_navigation.js`
- **commit**: `HEAD`

### ページ末尾の不要な相互遷移を削除
- **変更**: 最新トレンド末尾の生成AI年表リンクと、デイリーログ末尾の最新トレンドリンクを削除した。
- **理由**: 末尾から別ページへ移動する導線を絞り、各ページの主要な出口だけを残すため。
- **対象**: `history/news.html`、`history/daily.html`、`test/test_news_navigation_layout.js`、`test/test_daily_navigation.js`
- **commit**: `HEAD`

### 最新トレンドのレポート全文を先読み
- **変更**: 最新トレンドに登場するレポート全文を、カードの出典から重複なくページ表示直後に先読みするようにした。過去ログは従来どおりタップ時読み込みのままにした。
- **理由**: 最新トレンドのカードをタップした直後に「読み込み中…」が表示される待ち時間をなくすため。
- **対象**: `history/news.html`、`history/archive.html`、`history/report-modal.js`、`test/test_report_modal_preload.js`
- **commit**: `HEAD`

### AI HISTORYナビの用語集グローを共通化
- **変更**: 用語集リンク専用の発光強化を削除し、デイリーや最新トレンドと同じ共通ナビスタイルへ戻した。
- **理由**: 用語集だけ発光が強く見える状態になったため。
- **対象**: `history/index.html`、`test/test_index_glossary_glow.js`
- **commit**: `HEAD`

### AI HISTORYナビの用語集グロー再強化
- **変更**: 用語集リンクの紫色の境界線・背景・文字グロー・外側グローをさらに強めた。
- **理由**: 前回の控えめな発光強化では、画面上で変化が分かりにくかったため。
- **対象**: `history/index.html`、`test/test_index_glossary_glow.js`
- **commit**: `HEAD`

### AI HISTORYナビの用語集グロー強化
- **変更**: AI HISTORYの用語集リンクに紫色の境界線と通常時の外側グローを追加した。
- **理由**: 用語集だけ他のナビリンクより発光が弱く、視認性が低かったため。
- **対象**: `history/index.html`、`test/test_index_glossary_glow.js`
- **commit**: `HEAD`

### スマホ版AI HISTORYヒーロー配置の復元
- **変更**: スマホ版ヒーローの高さを画面全体へ戻し、`SYSTEM ONLINE`以下を元の中央配置に戻した。
- **理由**: 上部の余白を含めてシンプルな入口として見せる元の構成を維持するため。
- **対象**: `history/index.html`、`test/test_index_hero_layout.js`
- **commit**: `HEAD`

## 2026-09-17

### スマホ版AI HISTORYヒーロー上部余白の調整
- **変更**: スマホ幅のヒーロー領域の高さから固定ナビの実高さを差し引き、`SYSTEM ONLINE`より上の余白を縮めた。
- **理由**: 固定ナビを含む画面全体で中央配置していたため、ヒーロー上部の空きが大きく見えていたため。
- **対象**: `history/index.html`、`test/test_index_hero_layout.js`
- **commit**: `HEAD`

### スマホ版AI HISTORYの用語集リンク間隔を統一
- **変更**: 用語集リンクを右端へ押し出していた余白を削除し、他のナビリンクと同じ6px間隔で連続して並べた。
- **理由**: 用語集だけが離れて表示され、4つのナビリンクが一つのグループに見えなかったため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### AI HISTORYナビの三角記号を削除
- **変更**: 生成AI年表・最新トレンド・デイリーのナビ表記から三角記号を削除し、用語集を含む4リンクをスマホ幅で1行に収めやすくした。
- **理由**: 三角記号が各ピルの幅を広げ、用語集だけが2行目へ落ちていたため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### AI HISTORYのナビに用語集を追加
- **変更**: AI HISTORYのナビリンク3つをスマホ幅で左寄せに戻し、右端に紫色の「用語集」リンクを追加した。
- **理由**: 3つの移動リンクを左から読む流れを保ちつつ、関連する用語集へも同じナビから移動できるようにするため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### スマホ版AI HISTORYの検索欄を拡張
- **変更**: スマホ幅で検索欄をロゴのすぐ右まで広げ、最大200pxで表示しつつ、狭い画面では自動的に縮むようにした。
- **理由**: 検索欄が狭く、入力欄内のプレースホルダーが途中で切れていたため。
- **対象**: `history/index.html`、`test/test_index_search_layout.js`
- **commit**: `HEAD`

### スマホ版AI HISTORYの検索欄をロゴ右側へ移動
- **変更**: スマホ幅で検索欄をAI HISTORYロゴと同じ最上段の右側へ配置し、ページ移動リンクはその下段中央に残した。
- **理由**: 検索欄が3つのページ移動リンクのさらに下にあり、ヘッダーの縦幅が大きくなっていたため。
- **対象**: `history/index.html`、`test/test_index_search_layout.js`
- **commit**: `HEAD`

### スマホ版AI HISTORYのナビリンクを中央寄せ
- **変更**: スマホ幅で生成AI年表・最新トレンド・デイリーのナビリンク群を全幅の中央に配置し、6px間隔で等間隔に並べた。
- **理由**: 3つのリンクが左寄せだと、AI HISTORYロゴとのまとまりが崩れて見えたため。
- **対象**: `history/index.html`、`test/test_index_navigation_layout.js`
- **commit**: `HEAD`

### スマホ版ニュースフィードのナビロゴを1行化
- **変更**: `news.html`のスマホ用ナビで「AI NEWS FEED」の折り返しを禁止し、字間を0.1em、リンク間隔を6px、リンク内余白を4px 10pxへ調整した。
- **理由**: デイリーログと同じ文字数のロゴが、文字ごとの描画幅とナビ内余白の差で2行に折り返されていたため。
- **対象**: `history/news.html`、`test/test_news_navigation_layout.js`
- **commit**: `HEAD`

### スマホ音声カードの速度操作列を縮小
- **変更**: スマホ幅で1倍・1.5倍・2倍のボタンを縮小し、「視聴済み」チェックボックスを2倍ボタンの直後へ移動した。タイトルは下段の1行表示を維持した。
- **理由**: 速度操作とチェックボックスを同じ操作列にまとめ、タイトルとの上下の距離と横方向のバランスを整えるため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声カードの行間とチェック位置を調整
- **変更**: スマホ幅で速度操作とタイトルの間に8pxの行間を追加し、タイトル行の「視聴済み」チェックボックスを2px下へ調整した。
- **理由**: 速度操作とタイトルが近く、チェックボックスもタイトルの基準位置よりわずかに上へ見えていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声タイトルの1行表示を復元
- **変更**: スマホ幅では速度ボタンをグリッドの幅計算から外して上段右へ絶対配置し、タイトルがチェックボックス直前まで1行で表示できるようにした。タイトルの折り返しと省略記号を解除した。
- **理由**: 速度ボタンの幅によりタイトル列が狭くなり、タイトルが途中で省略されていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声タイトルの省略表示を解除
- **変更**: スマホ幅ではチェックボックス用の右列だけを確保し、音声タイトルを省略記号で切らずに自然に折り返して全文表示するようにした。
- **理由**: 長いタイトルが途中で途切れ、内容を最後まで確認できなくなっていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声カードの速度操作と視聴済み表示を再配置
- **変更**: スマホ幅で1倍・1.5倍・2倍の速度操作をカード上段右へ移し、「視聴済み」は文言を隠してタイトル行右端へ配置した。タイトルはチェックボックス用の右列を確保し、1行を超える場合は省略表示するようにした。チェックボックスには読み上げ用ラベルを追加した。
- **理由**: 速度操作と視聴済みの位置関係を整理し、タイトルとの誤タップや長いタイトルによる重なりを防ぐため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーの送り操作と再生時間の間隔を調整
- **変更**: スマホ幅でシークバー全体を8px右へ寄せ、10秒送りと左側の再生時間の間隔を12pxから20pxへ広げた。
- **理由**: 10秒送りと再生バー左側の時間表示が近く、操作列とシークバーの境界が分かりにくかったため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーの操作間隔を再調整
- **変更**: スマホ幅で再生・10秒操作ボタンの占有幅を36pxに詰め、操作列を左右8px寄せた。送りボタンと左側の時刻表示の間には12pxの間隔を設けた。
- **理由**: 操作ボタン同士は離れて見える一方、送りボタンと再生バー左側の時刻表示は近すぎ、操作群とシークバーの区切りが不均衡だったため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーの操作列とシークバーのバランス調整
- **変更**: スマホ幅で操作列を内側の余白へ8px寄せ、操作ボタン間を0px、時刻表示を30px、シークバーとの間隔を6pxに整理した。44pxのタップ領域は維持した。
- **理由**: 操作アイコンを縮小した後も操作列の占有幅が大きく、シークバーが短く見えていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーの操作アイコンを縮小
- **変更**: スマホ幅だけ再生アイコンを28pxから22px、10秒操作アイコンを34pxから28pxへ縮小した。各ボタンの44pxタップ領域とiPad・PC幅のサイズは維持した。
- **理由**: スマホ版では操作アイコンが音声パネル内で大きく見え、再生バーとのバランスを崩していたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーのシークバーを拡張
- **変更**: スマホ幅で操作ボタン間と時刻表示の余白を整理し、再生バーに使える横幅を増やした。360px以下の画面では従来の圧縮レイアウトを維持した。
- **理由**: 操作列をシークバーの左側へ移動した結果、再生バーが短くなり、操作列とのバランスが崩れていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声プレイヤーの操作列をシークバー左側へ移動
- **変更**: スマホ幅でも再生・10秒戻し・10秒送りを、シークバーと同じ行の左側に配置した。狭い画面では操作列とバーの隙間を縮め、横はみ出しを抑えた。
- **理由**: iPad版とスマホ版で操作の並びが異なり、スマホでは補助操作がシークバーの下に孤立していたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### 音声パネルのNotebookLMラベルを削除
- **変更**: 音声パネルに表示していた日付付きのNotebookLM音声ラベルを削除し、タイトルと再生操作だけの構成にした。削除後もスマホの速度操作はタイトル下の位置を維持した。
- **理由**: 音声の提供元名は再生操作の判断に不要で、タイトル周辺の情報量と窮屈さを増やしていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声パネルの行間をタイトル下だけに限定
- **変更**: 音声情報グリッド全体の行間を元に戻し、Listen Toとタイトルの間隔は従来どおりにした。タイトルと説明文・速度操作の行だけに12pxの追加間隔を設定した。
- **理由**: 前回の行間追加がListen Toとタイトルの間にも適用され、意図せず上段の余白まで広がっていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### スマホ音声パネルのタイトルと速度操作の行間を拡大
- **変更**: スマホ幅の音声情報グリッドに12pxの行間を追加し、タイトルと1倍・1.5倍・2倍の速度ボタンを離した。iPad・PC幅の配置は変更していない。
- **理由**: スマホでタイトル直下の速度ボタンが近く、音声タイトルと操作群の区切りが窮屈に見えていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### iPad幅の速度操作と視聴済みの間隔を拡大
- **変更**: 900px以上の音声パネルで、速度ボタン群と「視聴済み」の間隔を14pxから28pxへ広げた。スマホ幅の配置は変更していない。
- **理由**: iPadで2倍ボタンと視聴済みチェックボックスが近く、誤タップしやすかったため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

### 再生アイコンの表示サイズを拡大
- **変更**: 円なしの再生／停止アイコンを22pxから28pxへ拡大し、クリック領域44pxは維持した。
- **理由**: スマホ表示で再生アイコンが10秒操作アイコンに比べて小さく見えていたため。
- **対象**: `history/daily.html`、`test/test_audio_layout.js`
- **commit**: `HEAD`

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
