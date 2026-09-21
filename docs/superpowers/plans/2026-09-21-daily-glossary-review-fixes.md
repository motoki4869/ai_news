# 日次ニュース更新・用語集レビュー指摘の修正計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** solレビューで見つかった日次ニュース・用語集更新フローの失敗検知、再実行、入力検証、原子的書き込み、テスト、競合対策をすべて修正する。

**Architecture:** 日次ジョブはプロンプトの機械判定可能な`SUMMARY: OK:` / `SUMMARY: ERROR:`を検証し、失敗時に成功後処理へ進まない。用語集生成器は入力を厳格に検証して一時ファイルから原子的に置換する。日次・週次の両フローはリポジトリ単位のmkdirロックを共有し、同時実行を防ぐ。

**Tech Stack:** Bash、Python 3、Node.js built-in test runner、Markdownプロンプト、Git。

**Spec:** solレビュー（thread `01a0c332-6433-7c20-8ea4-2368cb21ad59`）のMajor 3件・Minor 4件。

## Global Constraints

- 日本語のプロンプト・ドキュメントを維持する。
- 用語集の原本は`docs/glossary.md`、生成物は`scripts/generate_glossary_data.py`で生成する。
- 日次処理のClaude版・Codex版プロンプトは検索ツール名以外の手順を一致させる。
- 生成失敗時は既存生成物を壊さず、終了コード1で通知可能にする。
- 変更後は関連テスト、全Nodeテスト、全Pythonテスト、差分検査を実行し、commit・pushする。

---

### Task 1: 日次ジョブの機械判定可能な成功・失敗処理

**Files:**
- Modify: `scripts/daily_news.sh`
- Modify: `scripts/daily_news_prompt.txt`
- Modify: `scripts/daily_news_prompt.codex.txt`
- Test: `test/test_daily_prompt_glossary.js`
- Test: `test/test_daily_news.sh`

- [x] **Step 1: Write failing tests**
  - 両プロンプトに`SUMMARY: OK:`と`SUMMARY: ERROR:`の仕様があることを検証する。
  - 当日分が既に存在しても、重複追加だけを省略して生成・commit手順へ進むことを検証する。
  - `daily_news.sh`が終了コード0の`SUMMARY: ERROR:`を失敗として終了することを検証する。

- [x] **Step 2: Run tests and verify failure**
  - `node --test test/test_daily_prompt_glossary.js`
  - `bash test/test_daily_news.sh`
  - 期待結果は、現行プロンプトに機械判定仕様がなく、シェルがエラーSummaryを成功扱いするための失敗。

- [x] **Step 3: Implement minimal behavior**
  - プロンプトの成功Summaryを`SUMMARY: OK: ...`、失敗Summaryを`SUMMARY: ERROR: ...`に統一する。
  - 同日見出しが存在する場合はニュース追加を省略するだけにし、手順8・9は継続する。
  - `daily_news.sh`で`SUMMARY: ERROR:`を検出したら`STATUS=1`へ変更し、LINE成功通知・音声更新へ進まない。

- [x] **Step 4: Run tests and verify pass**
  - `node --test test/test_daily_prompt_glossary.js`
  - `bash test/test_daily_news.sh`

### Task 2: 用語集生成器の厳格な入力検証と原子的書き込み

**Files:**
- Modify: `scripts/generate_glossary_data.py`
- Create: `test/test_generate_glossary_data.py`

- [x] **Step 1: Write failing tests**
  - 3列未満の表行、空の必須セル、不正なヘッダーを非0相当の例外で拒否するテストを書く。
  - 正常な表を生成できること、出力を一時ファイルから置換することを検証する。

- [x] **Step 2: Run tests and verify failure**
  - `python3 test/test_generate_glossary_data.py`

- [x] **Step 3: Implement minimal behavior**
  - 表行に行番号を保持し、表の列数・ヘッダー・必須セルを検証する。
  - `GlossaryParseError`を標準エラーへ出して終了コード1にする。
  - `tempfile.NamedTemporaryFile`と`os.replace`で`history/glossary-data.js`を原子的に更新する。

- [x] **Step 4: Run tests and verify pass**
  - `python3 test/test_generate_glossary_data.py`

### Task 3: 用語集メタデータの陳腐化要因を削除

**Files:**
- Modify: `docs/glossary.md`
- Modify: `.agents/skills/sync-news-html/SKILL.md`
- Modify: `test/test_daily_prompt_glossary.js`

- [x] **Step 1: Write failing test**
  - 用語集原本に日数・固定最終更新日のような日次処理で陳腐化するメタデータを要求しないことを検証する。

- [x] **Step 2: Run test and verify failure**
  - `node --test test/test_daily_prompt_glossary.js`

- [x] **Step 3: Implement minimal behavior**
  - `docs/glossary.md`の固定日数・最終更新行を削除し、対象データを静的な参照先だけにする。
  - 週次スキルのメタデータ更新指示を削除する。

- [x] **Step 4: Run test and verify pass**
  - `node --test test/test_daily_prompt_glossary.js`

### Task 4: 日次・週次フローの共有ロック

**Files:**
- Create: `scripts/lib/news_update_lock.sh`
- Modify: `scripts/daily_news.sh`
- Modify: `.agents/skills/sync-news-html/SKILL.md`
- Modify: `.gitignore`
- Test: `test/test_news_update_lock.sh`

- [x] **Step 1: Write failing test**
  - 最初のロック取得は成功し、2つ目の取得は失敗することを検証する。
  - 解放後は再取得できることを検証する。

- [x] **Step 2: Run test and verify failure**
  - `bash test/test_news_update_lock.sh`

- [x] **Step 3: Implement minimal behavior**
  - `mkdir`の原子性を利用したリポジトリ内ロックを実装する。
  - `daily_news.sh`はClaude起動前から終了処理までロックを保持する。
  - `sync-news-html`は編集開始前に同じロックを取得し、完了時に解放する手順を持つ。
  - ロックディレクトリを`.gitignore`へ追加する。

- [x] **Step 4: Run test and verify pass**
  - `bash test/test_news_update_lock.sh`

### Task 5: 回帰テスト、文書、統合検証

**Files:**
- Modify: `docs/CHANGELOG.md`
- Modify: `docs/superpowers/plans/2026-09-21-daily-glossary-review-fixes.md`

- [x] **Step 1: Run focused tests**
  - Task 1〜4のテストを実行する。

- [x] **Step 2: Run full verification**
  - `node --test test/*.js`
  - `python3 -m unittest discover -s test -p 'test_*.py'`
  - `bash -n scripts/daily_news.sh scripts/lib/news_update_lock.sh`
  - `git diff --check`

- [x] **Step 3: Update changelog and plan checkboxes**
  - レビュー指摘を解消した変更理由と対象を`docs/CHANGELOG.md`へ記録する。
  - 完了した計画項目をチェックする。

- [x] **Step 4: Commit and push**
  - 差分と作業ツリーを確認し、commit後に`main`へpushする。
