const test = require('node:test');
const assert = require('node:assert/strict');

const {
  getAdjacentDate,
  getSwipeDirection,
} = require('../history/daily-navigation.js');

const DATES = [
  '2026-07-05',
  '2026-07-09',
  '2026-07-10',
  '2026-08-27',
  '2026-08-28',
  '2026-08-29',
];

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
