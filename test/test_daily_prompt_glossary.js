const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

const ROOT = path.join(__dirname, '..');
const PROMPTS = [
  path.join(ROOT, 'scripts', 'daily_news_prompt.txt'),
  path.join(ROOT, 'scripts', 'daily_news_prompt.codex.txt'),
];
const GLOSSARY_SOURCE = fs.readFileSync(
  path.join(ROOT, 'docs', 'glossary.md'),
  'utf8',
);

test('日次ニュース更新プロンプトに用語集更新手順が含まれる', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(prompt, /docs\/glossary\.md/,
      `${path.basename(promptPath)} が用語集原本を参照していません`);
    assert.match(prompt, /generate_glossary_data\.py/,
      `${path.basename(promptPath)} が用語集データの再生成を指示していません`);
    assert.match(prompt, /history\/glossary-data\.js/,
      `${path.basename(promptPath)} が用語集生成物を扱っていません`);
    assert.match(prompt, /用語.*未収録|未収録.*用語/,
      `${path.basename(promptPath)} が新規用語の確認を指示していません`);
    assert.match(prompt, /SUMMARY:\s*OK:/,
      `${path.basename(promptPath)} が成功結果の機械判定形式を定義していません`);
    assert.match(prompt, /SUMMARY:\s*ERROR:/,
      `${path.basename(promptPath)} が失敗結果の機械判定形式を定義していません`);
  }
});

test('日次スクリプトはニュースと用語集の原本・生成物をcommit対象に含める', () => {
  const script = fs.readFileSync(path.join(ROOT, 'scripts', 'daily_news.sh'), 'utf8');
  for (const target of [
    'local news_file="everyday_news/${AI_NEWS_DATE:0:4}${AI_NEWS_DATE:5:2}.md"',
    'history/daily-data.js',
    'docs/glossary.md',
    'history/glossary-data.js',
  ]) {
    assert.ok(script.includes(target), `日次スクリプトが${target}をcommit対象に含めていません`);
  }
  assert.match(script, /git_with_daily_news_hooks -C "\$REPO_DIR" commit --only[\s\S]*"\$\{targets\[@\]\}"/,
    '日次スクリプトが更新対象だけをcommitして通常Gitインデックスを同期しません');
  assert.match(script, /AI作業用コピー.*\.gitが存在します/,
    'AIへ.gitのない作業用コピーを渡していません');
  assert.match(script, /HEAD_HAS_NEWS_DATE=0[\s\S]*REMOTE_HAS_NEWS_DATE=1[\s\S]*SAVED_SOURCE_DATE.*REMOTE_HAS_NEWS_DATE/,
    '公開済み日の再実行を判定していません');
  assert.match(script, /本日のニュースは既に公開済みのため追加更新をスキップ/,
    '公開済み日の再実行でAIによる記事追加をスキップしていません');
  assert.ok(
    script.indexOf('line_notification_has_current_message "$AGENT_REPO_DIR/everyday_news/line_message.txt"')
      < script.indexOf('! sync_agent_outputs;'),
    'AI作業用コピー内のLINE通知文を検証する前に本体へ同期しています',
  );
  assert.match(script, /NEWS_ALREADY_PUBLISHED[\s\S]*line_notification_has_current_message "\$LINE_MSG_FILE"/,
    '公開済み日のLINE再送前に当日日付の通知文を再検査していません');
});

test('日次ニュース更新プロンプトは当日分が5件未満なら補い、見出しは重複作成しない', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(
      prompt,
      /実行日と完全一致する日付のセクション[\s\S]*5件未満なら最低5件まで不足分を補い、5件以上7件未満なら追加候補を調査して重要ニュースがあれば7件まで補う/,
      `${path.basename(promptPath)} が同日再実行時の最低5件と6〜7件の目標を指示していません`,
    );
  }
});

test('日次ニュース更新プロンプトは5件未満の成功を禁止し機械検査する', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(prompt, /5件は最低件数/,
      `${path.basename(promptPath)} が最低5件を指定していません`);
    assert.match(prompt, /validate_daily_news\.py[\s\S]*--min-items 5/,
      `${path.basename(promptPath)} がcommit前の件数検査を指示していません`);
  }
});

test('日次ニュース更新プロンプトは5件で調査を止めず、6〜7件を目標にする', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(prompt, /通常6〜7件を目標/,
      `${path.basename(promptPath)} が通常の目標件数を6〜7件にしていません`);
    assert.match(prompt, /5件見つけた時点で調査を終えない/,
      `${path.basename(promptPath)} が最低件数到達後の追加調査を指示していません`);
    assert.match(prompt, /重要ニュースがあれば7件まで/,
      `${path.basename(promptPath)} が重要ニュースの追加を指示していません`);
    assert.match(prompt, /無理に水増ししない/,
      `${path.basename(promptPath)} がニュースの水増しを禁止していません`);
    assert.match(prompt, /既存記事が7件を超えていても削除せず/,
      `${path.basename(promptPath)} が既存記事の過剰な削除を防いでいません`);
    assert.match(prompt, /公開済みの日の再実行は日次スクリプトがAI更新をスキップする/,
      `${path.basename(promptPath)} が公開後の再実行ルールを説明していません`);
  }
});

test('日次ニュース更新プロンプトはAI自身にcommit・pushさせない', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');
    assert.match(prompt, /AI自身はgit add・commit・pushを行わず、日次スクリプトに任せる/,
      `${path.basename(promptPath)} がcommit・pushを呼び出し元へ委ねていません`);
  }
});

test('日次ニュース更新プロンプトは同日再実行でもLINE通知文を再生成する', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(
      prompt,
      /当日分が(?:既に)?存在[\s\S]*line_message\.txt[\s\S]*(?:再生成|書き直|更新)/,
      `${path.basename(promptPath)} が同日再実行時のLINE通知再生成を指示していません`,
    );
  }
});

test('日次ニュース更新プロンプトは変更なしを正常な更新結果として扱う', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(
      prompt,
      /変更がない|変更なし|commit.*不要|commit.*無い[\s\S]*SUMMARY:\s*OK:/i,
      `${path.basename(promptPath)} が変更なしの正常系を定義していません`,
    );
  }
});

test('日次ニュース更新プロンプトの警告失敗経路もSUMMARY: ERROR:を使う', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(
      prompt,
      /警告[\s\S]*SUMMARY:\s*ERROR:/,
      `${path.basename(promptPath)} の警告失敗経路がSUMMARY: ERROR:になっていません`,
    );
  }
});

test('Claude版とCodex版の日次プロンプトは検索ツール名とCodex向けツール説明以外が一致する', () => {
  const [claudePrompt, codexPrompt] = PROMPTS.map((promptPath) =>
    fs.readFileSync(promptPath, 'utf8'),
  );
  const normalize = (prompt) => prompt
    .replace(/WebSearchを使って/g, '<SEARCH_TOOL>を使って')
    .replace(/web_searchツールを使って/g, '<SEARCH_TOOL>を使って')
    .replace(/^【Codexでのツールの使い方[\s\S]*?【ここまで】\n\n/, '');

  assert.equal(normalize(claudePrompt), normalize(codexPrompt));
});

test('用語集原本に日次処理で陳腐化する固定メタデータを持たせない', () => {
  assert.doesNotMatch(GLOSSARY_SOURCE, /history\/daily-data\.js`（\d+日分）/);
  assert.doesNotMatch(GLOSSARY_SOURCE, /- 最終更新: \d{4}-\d{2}-\d{2}/);
});

test('Codex版の日次プロンプトはCodexに存在するツールで作業できるよう案内する', () => {
  const codexPrompt = fs.readFileSync(PROMPTS[1], 'utf8');

  assert.match(codexPrompt, /^【Codexでのツールの使い方/);
  assert.match(codexPrompt, /apply_patch/);
  assert.match(codexPrompt, /web_searchツール/);
  assert.doesNotMatch(codexPrompt, /browser_use/);
});
