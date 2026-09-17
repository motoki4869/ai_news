const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const NEWS_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'news.html'),
  'utf8',
);

test('スマホ幅ではニュースフィードのナビロゴを1行に収める', () => {
  assert.match(
    NEWS_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-logo\s*\{[^}]*white-space:\s*nowrap;[^}]*letter-spacing:\s*0\.1em;/s,
  );
  assert.match(
    NEWS_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-links\s*\{[^}]*gap:\s*6px;[^}]*\}/s,
  );
  assert.match(
    NEWS_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.nav-links a\s*\{[^}]*padding:\s*4px 10px;/s,
  );
});
