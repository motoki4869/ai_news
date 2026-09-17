const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { formatTime, bufferedEnd, percentOf } = require('../history/audio-player.js');
const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

/* TimeRangesの代わり。audio.buffered と同じ読み方ができればよい。 */
function timeRanges(ranges) {
  return {
    length: ranges.length,
    start: i => ranges[i][0],
    end: i => ranges[i][1],
  };
}

test('再生時間は分:秒で表示する', () => {
  assert.equal(formatTime(0), '0:00');
  assert.equal(formatTime(9), '0:09');
  assert.equal(formatTime(65), '1:05');
  assert.equal(formatTime(599), '9:59');
});

test('1時間を超える音声は時:分:秒で表示する', () => {
  assert.equal(formatTime(3600), '1:00:00');
  assert.equal(formatTime(3723), '1:02:03');
});

test('秒未満は切り捨てる', () => {
  assert.equal(formatTime(59.9), '0:59');
});

test('長さが未確定のうちは固定幅のプレースホルダを返す', () => {
  assert.equal(formatTime(Number.NaN), '--:--');
  assert.equal(formatTime(Number.POSITIVE_INFINITY), '--:--');
  assert.equal(formatTime(-1), '--:--');
});

test('読み込み済み範囲は再生位置を含む範囲の終端を返す', () => {
  const audio = { currentTime: 30, buffered: timeRanges([[0, 10], [25, 80]]) };

  assert.equal(bufferedEnd(audio), 80);
});

test('どの読み込み済み範囲にも入っていなければ0を返す', () => {
  const audio = { currentTime: 200, buffered: timeRanges([[0, 10], [25, 80]]) };

  assert.equal(bufferedEnd(audio), 0);
});

test('読み込みが始まっていない音声では0を返す', () => {
  assert.equal(bufferedEnd({ currentTime: 0, buffered: timeRanges([]) }), 0);
  assert.equal(bufferedEnd(null), 0);
});

test('バーの割合は0〜100に収める', () => {
  assert.equal(percentOf(30, 120), 25);
  assert.equal(percentOf(200, 120), 100);
  assert.equal(percentOf(-5, 120), 0);
});

test('長さが未確定のうちはバーを伸ばさない', () => {
  assert.equal(percentOf(30, 0), 0);
  assert.equal(percentOf(30, Number.NaN), 0);
});

test('音声パネルはブラウザ標準のコントロールを使わない', () => {
  const audioTag = DAILY_HTML.match(/<audio[^>]*id="audio-player"[^>]*>/);

  assert.ok(audioTag, '<audio id="audio-player"> が見つからない');
  assert.doesNotMatch(audioTag[0], /\bcontrols\b/);
});

test('音声パネルに再生ボタンとシークバーを表示する', () => {
  assert.match(DAILY_HTML, /id="audio-play"/);
  assert.match(DAILY_HTML, /type="range"[^>]*id="audio-seek"|id="audio-seek"[^>]*type="range"/s);
});

test('シークバーには操作内容を読み上げるラベルを付ける', () => {
  assert.match(DAILY_HTML, /id="audio-seek"[\s\S]{0,200}aria-label="再生位置"/);
});
