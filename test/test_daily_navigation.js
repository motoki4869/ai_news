const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const {
  getAdjacentDate,
  getSwipeDirection,
  shouldIgnoreTouchStart,
} = require('../history/daily-navigation.js');

const DATES = [
  '2026-07-05',
  '2026-07-09',
  '2026-07-10',
  '2026-08-27',
  '2026-08-28',
  '2026-08-29',
];

const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

test('欠損日を飛ばして前後のニュース日を返す', () => {
  assert.equal(getAdjacentDate(DATES, '2026-07-05', 'next'), '2026-07-09');
  assert.equal(getAdjacentDate(DATES, '2026-07-09', 'previous'), '2026-07-05');
});

test('日付の端では隣の日付を返さない', () => {
  assert.equal(getAdjacentDate(DATES, '2026-07-05', 'previous'), null);
  assert.equal(getAdjacentDate(DATES, '2026-08-29', 'next'), null);
});

test('右スワイプは前の日、左スワイプは次の日へ進む', () => {
  assert.equal(getSwipeDirection(10, 100, 90, 110), 'previous');
  assert.equal(getSwipeDirection(90, 100, 10, 110), 'next');
});

test('短い移動と縦方向の移動はスワイプにしない', () => {
  assert.equal(getSwipeDirection(10, 100, 35, 105), null);
  assert.equal(getSwipeDirection(10, 100, 80, 180), null);
});

test('要約欄のリンク上ではスワイプ開始を無視しない', () => {
  const headlineLink = {
    closest(selector) {
      assert.equal(selector, 'button, input, select, textarea, audio');
      return null;
    },
  };
  const audioControl = {
    closest(selector) {
      assert.equal(selector, 'button, input, select, textarea, audio');
      return { tagName: 'BUTTON' };
    },
  };

  assert.equal(shouldIgnoreTouchStart(headlineLink), false);
  assert.equal(shouldIgnoreTouchStart(audioControl), true);
});

test('日付見出しを固定ナビに隠れない位置へスクロールする', () => {
  assert.match(DAILY_HTML, /\.day-head h2\s*\{[^}]*scroll-margin-top:\s*calc\(var\(--nav-h\)\s*\+\s*18px\);/s);
  assert.match(
    DAILY_HTML,
    /const dateHeading = dayHead\.querySelector\('h2'\);\s*if \(dateHeading\) dateHeading\.scrollIntoView\(/s,
  );
});

test('最新ボタンを日付見出し行の右端へ配置する', () => {
  const calendarHead = DAILY_HTML.match(/<div class="cal-head">[\s\S]*?<\/div>/)?.[0];
  assert.ok(calendarHead);
  assert.doesNotMatch(
    calendarHead,
    /id="cal-latest"/,
  );
  assert.match(DAILY_HTML, /dayHead\.append\(h2, countSpan, lineSpan, latestBtn\);/);
});

test('デイリーログ末尾には最新トレンドへの遷移を置かない', () => {
  assert.doesNotMatch(
    DAILY_HTML,
    /<div class="cta-back">[\s\S]*<a class="to-news" href="news\.html">/s,
  );
});
