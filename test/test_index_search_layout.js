const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('スマホ幅では検索ボックスをAI HISTORYロゴの右側へ移す', () => {
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-logo\s*\{[^}]*white-space:\s*nowrap;[^}]*\}/s,
  );
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-search\s*\{[^}]*order:\s*2;[^}]*width:\s*clamp\(/s,
  );
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-links\s*\{[^}]*order:\s*3;[^}]*width:\s*100%;/s,
  );
});
