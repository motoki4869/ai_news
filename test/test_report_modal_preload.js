const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const NEWS_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'news.html'),
  'utf8',
);
const ARCHIVE_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'archive.html'),
  'utf8',
);
const REPORT_MODAL_JS = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'report-modal.js'),
  'utf8',
);

test('最新トレンドはカード出典のレポートを先読みし、アーカイブは対象外にする', () => {
  assert.match(NEWS_HTML, /<body\s+data-page="news">/);
  assert.match(ARCHIVE_HTML, /<body\s+data-page="archive">/);
  assert.match(REPORT_MODAL_JS, /document\.body\.dataset\.page !== 'news'/);
  assert.match(
    REPORT_MODAL_JS,
    /document\.querySelectorAll\('\.news-card\[data-report\]'\)[\s\S]*?names\.forEach\(name => loadReport\(name\)\)/,
  );
  assert.match(REPORT_MODAL_JS, /preloadNewsReports\(\);/);
});
