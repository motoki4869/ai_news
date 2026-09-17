const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('AI HISTORYの用語集リンクは通常時も紫のグローを表示する', () => {
  assert.match(
    INDEX_HTML,
    /\.nav-links\s+\.to-glossary\s*\{[^}]*border-color:\s*rgba\(var\(--pill\),\s*0\.6\);[^}]*box-shadow:\s*0\s+0\s+12px\s+rgba\(var\(--pill\),\s*0\.35\);/s,
  );
});
