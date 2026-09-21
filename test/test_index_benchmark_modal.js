const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);
const GENERATIVE_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'generative.html'),
  'utf8',
);

for (const [pageName, html] of [['AI HISTORY', INDEX_HTML], ['生成AI年表', GENERATIVE_HTML]]) {
  test(`${pageName}のAI比較ボタンから2つの性能比較サイトを選べる`, () => {
    assert.match(html, /id="ai-benchmark-modal"[^>]*role="dialog"[^>]*aria-modal="true"/);
    assert.match(html, /<h2 id="ai-benchmark-title">最新AIの性能を比較する<\/h2>/);
    assert.match(html, /<button[^>]*aria-controls="ai-benchmark-modal"[^>]*>AI比較<\/button>/);
    assert.match(html, /href="https:\/\/arena\.ai\/leaderboard\/"[^>]*target="_blank"[^>]*rel="noopener"/);
    assert.match(html, /人間の投票による実用性・人気の比較/);
    assert.match(html, /href="https:\/\/artificialanalysis\.ai\/"[^>]*target="_blank"[^>]*rel="noopener"/);
    assert.match(html, /event\.key === 'Escape'[\s\S]*setAiBenchmarkModalOpen\(false\)/);
  });
}

test('生成AI年表の上部ナビではAI HISTORYへの戻りリンクを右側に置く', () => {
  assert.match(
    GENERATIVE_HTML,
    /<div class="nav-links">\s*<button class="to-arena"[\s\S]*?<a class="to-history" href="index\.html">← AI HISTORY<\/a>\s*<\/div>/s,
  );
});
