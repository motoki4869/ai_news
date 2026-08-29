const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const { createAudioHeardStore } = require('../history/audio-heard.js');
const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

function createStorage(initial = {}) {
  const values = { ...initial };
  return {
    getItem(key) { return values[key] ?? null; },
    setItem(key, value) { values[key] = String(value); },
  };
}

test('視聴済み状態を日付ごとに保存し、再生成後も復元する', () => {
  const storage = createStorage();
  const firstStore = createAudioHeardStore(storage);

  firstStore.set('2026-08-28', true);

  const restoredStore = createAudioHeardStore(storage);
  assert.equal(restoredStore.has('2026-08-28'), true);
  assert.equal(restoredStore.has('2026-08-29'), false);
});

test('チェックを外すと視聴済み状態を削除する', () => {
  const storage = createStorage();
  const store = createAudioHeardStore(storage);

  store.set('2026-08-28', true);
  store.set('2026-08-28', false);

  assert.equal(store.has('2026-08-28'), false);
});

test('音声パネルに視聴済みチェックボックスを表示する', () => {
  assert.match(DAILY_HTML, /id="audio-heard"[^>]*type="checkbox"|type="checkbox"[^>]*id="audio-heard"/);
  assert.match(DAILY_HTML, /LISTEN TO DAILY NEWS/);
});
