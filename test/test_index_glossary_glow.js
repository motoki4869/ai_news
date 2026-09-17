const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('AI HISTORYの用語集リンクは他のナビリンクと共通の発光を使う', () => {
  assert.doesNotMatch(
    INDEX_HTML,
    /\.nav-links\s+\.to-glossary\s*\{/s,
  );
});
