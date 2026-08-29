const test = require('node:test');
const assert = require('node:assert/strict');

const { seekAudio } = require('../history/audio-seek.js');

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
