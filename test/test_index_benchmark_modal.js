const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('AI比較ボタンから2つの性能比較サイトを選べる', () => {
  assert.match(INDEX_HTML, /id="ai-benchmark-modal"[^>]*role="dialog"[^>]*aria-modal="true"/);
  assert.match(INDEX_HTML, /<button[^>]*aria-controls="ai-benchmark-modal"[^>]*>AI比較<\/button>/);
  assert.match(INDEX_HTML, /href="https:\/\/arena\.ai\/leaderboard\/"[^>]*target="_blank"[^>]*rel="noopener"/);
  assert.match(INDEX_HTML, /href="https:\/\/artificialanalysis\.ai\/"[^>]*target="_blank"[^>]*rel="noopener"/);
  assert.match(INDEX_HTML, /event\.key === 'Escape'[\s\S]*setAiBenchmarkModalOpen\(false\)/);
});
