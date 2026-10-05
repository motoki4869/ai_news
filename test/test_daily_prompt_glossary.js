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

test('日次ニュース更新プロンプトは用語集関連ファイルをcommit対象に含める', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    const addLine = prompt.split('\n').find((line) => line.includes('git add'));
    assert.ok(addLine, `${path.basename(promptPath)} にgit addの指示がありません`);
    assert.match(addLine, /everyday_news\/\*\.md/,
      `${path.basename(promptPath)} が日次原本のcommit対象を明示していません`);
    assert.match(addLine, /history\/daily-data\.js/,
      `${path.basename(promptPath)} が日次生成物のcommit対象を明示していません`);
    assert.match(addLine, /docs\/glossary\.md/,
      `${path.basename(promptPath)} が用語集原本のcommit対象を明示していません`);
    assert.match(addLine, /history\/glossary-data\.js/,
      `${path.basename(promptPath)} が用語集生成物のcommit対象を明示していません`);
  }
});

test('日次ニュース更新プロンプトは当日分が5件未満なら補い、見出しは重複作成しない', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(
      prompt,
      /実行日と完全一致する日付のセクション[\s\S]*5件未満なら不足分を調査して補い/,
      `${path.basename(promptPath)} が同日再実行時に5件まで補うよう指示していません`,
    );
  }
});

test('日次ニュース更新プロンプトは5件未満の成功を禁止し機械検査する', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(prompt, /必ず5件以上/,
      `${path.basename(promptPath)} が最低5件を指定していません`);
    assert.match(prompt, /validate_daily_news\.py[\s\S]*--min-items 5/,
      `${path.basename(promptPath)} がcommit前の件数検査を指示していません`);
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

test('Claude版とCodex版の日次プロンプトは検索ツール名以外が一致する', () => {
  const [claudePrompt, codexPrompt] = PROMPTS.map((promptPath) =>
    fs.readFileSync(promptPath, 'utf8'),
  );
  const normalize = (prompt) => prompt
    .replace(/WebSearchを使って/g, '<SEARCH_TOOL>を使って')
    .replace(/browser_useツールを使って/g, '<SEARCH_TOOL>を使って');

  assert.equal(normalize(claudePrompt), normalize(codexPrompt));
});

test('用語集原本に日次処理で陳腐化する固定メタデータを持たせない', () => {
  assert.doesNotMatch(GLOSSARY_SOURCE, /history\/daily-data\.js`（\d+日分）/);
  assert.doesNotMatch(GLOSSARY_SOURCE, /- 最終更新: \d{4}-\d{2}-\d{2}/);
});
