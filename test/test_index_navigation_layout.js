const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const INDEX_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'index.html'),
  'utf8',
);

test('スマホ幅ではAI HISTORYのナビリンクを左寄せで等間隔に並べる', () => {
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-links\s*\{[^}]*justify-content:\s*flex-start;[^}]*width:\s*100%;/s,
  );
  assert.match(
    INDEX_HTML,
    /<a\s+class="to-glossary"\s+href="glossary\.html">用語集<\/a>/,
  );
  assert.match(
    INDEX_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-links\s+\.to-glossary\s*\{[^}]*margin-left:\s*auto;/s,
  );
});
