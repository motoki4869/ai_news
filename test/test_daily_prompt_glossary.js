const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');

const ROOT = path.join(__dirname, '..');
const PROMPTS = [
  path.join(ROOT, 'scripts', 'daily_news_prompt.txt'),
  path.join(ROOT, 'scripts', 'daily_news_prompt.codex.txt'),
];

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
  }
});

test('日次ニュース更新プロンプトは用語集関連ファイルをcommit対象に含める', () => {
  for (const promptPath of PROMPTS) {
    const prompt = fs.readFileSync(promptPath, 'utf8');

    assert.match(prompt, /docs\/glossary\.md[\s\S]*history\/glossary-data\.js/,
      `${path.basename(promptPath)} が用語集関連ファイルのcommitを指示していません`);
  }
});
