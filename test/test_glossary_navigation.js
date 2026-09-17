const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const GLOSSARY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'glossary.html'),
  'utf8',
);

test('用語集上部ナビを最新トレンド、デイリーの順に並べる', () => {
  assert.match(
    GLOSSARY_HTML,
    /<div class="nav-links">\s*<a class="to-news" href="news\.html">最新トレンド<\/a>\s*<a class="to-daily" href="daily\.html">デイリー<\/a>\s*<\/div>/s,
  );
});

test('用語集末尾の遷移を全体年表、最新トレンド、デイリーログの順に並べる', () => {
  assert.match(
    GLOSSARY_HTML,
    /<div class="cta-back">\s*<a class="to-index" href="index\.html">← AI HISTORY 全体年表<\/a>\s*<a class="to-news" href="news\.html">最新トレンド →<\/a>\s*<a class="to-daily" href="daily\.html">デイリーログ →<\/a>\s*<\/div>/s,
  );
});
