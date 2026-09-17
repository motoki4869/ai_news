const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('スマホ幅ではヒーローの高さから固定ナビ分を差し引く', () => {
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.hero\s*\{[^}]*min-height:\s*calc\(100vh\s*-\s*var\(--nav-h\)\);/s,
  );
});
