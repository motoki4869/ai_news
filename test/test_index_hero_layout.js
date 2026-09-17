const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('スマホ幅ではヒーローを画面全体の高さで中央配置する', () => {
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.hero\s*\{[^}]*padding-top:\s*150px;/s,
  );
  assert.doesNotMatch(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.hero\s*\{[^}]*min-height:\s*calc\(100vh\s*-\s*var\(--nav-h\)\);/s,
  );
});
