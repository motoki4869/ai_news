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
    /\.nav-links\s+\.to-glossary\s*\{[^}]*border-color:\s*rgba\(var\(--pill\),\s*0\.8\);[^}]*background:\s*rgba\(var\(--pill\),\s*0\.1\);[^}]*box-shadow:\s*0\s+0\s+10px\s+rgba\(var\(--pill\),\s*0\.45\),\s*0\s+0\s+22px\s+rgba\(var\(--pill\),\s*0\.22\);[^}]*text-shadow:\s*0\s+0\s+8px\s+rgba\(var\(--pill\),\s*0\.65\);/s,
  );
});
