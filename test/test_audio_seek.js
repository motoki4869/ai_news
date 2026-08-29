const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { seekAudio, setPlaybackRate } = require('../history/audio-seek.js');
const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

test('10秒戻す操作で再生位置を0秒未満にしない', () => {
  const audio = { currentTime: 5, duration: 120 };

  const changed = seekAudio(audio, -10);

  assert.equal(changed, true);
  assert.equal(audio.currentTime, 0);
});

test('10秒進める操作で音声の長さを超えない', () => {
  const audio = { currentTime: 115, duration: 120 };

  seekAudio(audio, 10);

  assert.equal(audio.currentTime, 120);
});

test('メタデータ読み込み前でも再生位置を進められる', () => {
  const audio = { currentTime: 0, duration: Number.NaN };

  const changed = seekAudio(audio, 10);

  assert.equal(changed, true);
  assert.equal(audio.currentTime, 10);
});

test('再生速度は1倍、1.5倍、2倍だけ設定できる', () => {
  const audio = { playbackRate: 1 };

  assert.equal(setPlaybackRate(audio, 2), true);
  assert.equal(audio.playbackRate, 2);
  assert.equal(setPlaybackRate(audio, 1.5), true);
  assert.equal(audio.playbackRate, 1.5);
  assert.equal(setPlaybackRate(audio, 1), true);
  assert.equal(audio.playbackRate, 1);
  assert.equal(setPlaybackRate(audio, 1.25), false);
  assert.equal(audio.playbackRate, 1);
});

test('音声パネルに1倍、1.5倍、2倍の操作ボタンを表示する', () => {
  assert.match(DAILY_HTML, /id="audio-speed-1"[^>]*data-audio-rate="1"/);
  assert.match(DAILY_HTML, /id="audio-speed-1-5"[^>]*data-audio-rate="1\.5"/);
  assert.match(DAILY_HTML, /id="audio-speed-2"[^>]*data-audio-rate="2"/);
});

test('再生速度ボタンは同じ幅で表示する', () => {
  assert.match(DAILY_HTML, /\.audio-speed button\s*\{[^}]*min-width:\s*48px;/s);
});
