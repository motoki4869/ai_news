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

test('レポート全文に概要・章目次・読了目安を自動表示する', () => {
  assert.match(REPORT_MODAL_JS, /function createReadingGuide\(section, reportIndex\)/);
  assert.match(REPORT_MODAL_JS, /まず押さえる3点/);
  assert.match(REPORT_MODAL_JS, /読了目安 約\$\{minutes\}分/);
  assert.match(REPORT_MODAL_JS, /heading\.scrollIntoView\(\{ behavior: 'smooth'/);
  assert.match(REPORT_MODAL_JS, /section\.querySelectorAll\('h2, h3, h4'\)/);
  assert.match(REPORT_MODAL_JS, /\.rpt-section > p, \.rpt-section > ul > li, \.rpt-section td, \.rpt-summary-list li/);
  assert.match(NEWS_HTML, /\.rpt-reading-guide/);
  assert.match(ARCHIVE_HTML, /\.rpt-reading-guide/);
});

test('章目次は三本線ボタンから開くオーバーレイにする', () => {
  assert.match(REPORT_MODAL_JS, /report-modal-toc-toggle/);
  assert.match(REPORT_MODAL_JS, /aria-expanded/);
  assert.match(REPORT_MODAL_JS, /function setTocOpen\(open\)/);
  assert.match(REPORT_MODAL_JS, /report-modal-toc/);
  assert.match(REPORT_MODAL_JS, /tocPanel\.hidden = !open/);
  assert.match(NEWS_HTML, /\.report-modal-toc-toggle/);
  assert.match(NEWS_HTML, /\.report-modal-toc/);
  assert.match(ARCHIVE_HTML, /\.report-modal-toc-toggle/);
  assert.match(ARCHIVE_HTML, /\.report-modal-toc/);
});

test('要約は冒頭文の連結ではなく3つの要点として表示する', () => {
  assert.match(REPORT_MODAL_JS, /function buildSummaryPoints\(paragraphs\)/);
  assert.match(REPORT_MODAL_JS, /rpt-summary-list/);
  assert.match(REPORT_MODAL_JS, /buildSummaryPoints\(paragraphs\)/);
  assert.match(NEWS_HTML, /\.rpt-summary-list/);
  assert.match(ARCHIVE_HTML, /\.rpt-summary-list/);
});

test('3つの要点は省略記号なしで全文表示する', () => {
  assert.doesNotMatch(REPORT_MODAL_JS, /shortened/);
  assert.match(REPORT_MODAL_JS, /return points\.slice\(0, 3\);/);
  assert.match(NEWS_HTML, /\.rpt-summary-list li \{[^}]*overflow-wrap: anywhere/);
  assert.doesNotMatch(NEWS_HTML, /\.rpt-summary-list li \{[^}]*-webkit-line-clamp/);
  assert.doesNotMatch(ARCHIVE_HTML, /\.rpt-summary-list li \{[^}]*-webkit-line-clamp/);
});

test('レポート導入部の余白を広げ、要点下の点線を外す', () => {
  for (const html of [NEWS_HTML, ARCHIVE_HTML]) {
    assert.match(html, /\.report-modal-header \{[^}]*padding: 14px 14px 12px/);
    assert.match(html, /\.rpt-summary \{[^}]*padding-bottom: 12px/);
    assert.doesNotMatch(html, /\.rpt-summary \{[^}]*border-bottom/);
  }
});

test('スマホでも読了目安を導入ラベルと同じ行に置く', () => {
  assert.doesNotMatch(NEWS_HTML, /\.rpt-reading-meta \{[^}]*flex-direction: column/);
  assert.doesNotMatch(ARCHIVE_HTML, /\.rpt-reading-meta \{[^}]*flex-direction: column/);
});

test('左上の章一覧は左側から開くドロワーにする', () => {
  assert.match(NEWS_HTML, /\.report-modal-toc \{[^}]*justify-content: flex-start/);
  assert.match(NEWS_HTML, /border-right: 1px solid rgba\(0,229,255,0\.25\)/);
  assert.match(NEWS_HTML, /report-toc-in-left/);
  assert.match(ARCHIVE_HTML, /\.report-modal-toc \{[^}]*justify-content: flex-start/);
  assert.match(ARCHIVE_HTML, /border-right: 1px solid rgba\(0,229,255,0\.25\)/);
  assert.match(ARCHIVE_HTML, /report-toc-in-left/);
});

test('スマホの章一覧シートは上の余白を抑えて表示する', () => {
  for (const html of [NEWS_HTML, ARCHIVE_HTML]) {
    assert.match(
      html,
      /@media \(max-width: 768px\) \{[\s\S]*?\.report-modal-toc-sheet \{[^}]*height: auto;[^}]*max-height: calc\(100% - 24px\)/,
    );
  }
});
