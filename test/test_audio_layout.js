const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

test('スマホ幅ではNotebookLM音声の右側に再生速度を表示する', () => {
  assert.match(
    DAILY_HTML,
    /grid-template-areas:\s*\n\s*"kicker heard"\s*\n\s*"title\s+title"\s*\n\s*"desc\s+speed"/s,
  );
  assert.match(
    DAILY_HTML,
    /\.audio-speed\s*\{[^}]*grid-area:\s*speed;[^}]*justify-self:\s*end;/s,
  );
});

test('再生ボタンは34pxの円形で表示する', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-play\s*\{[^}]*width:\s*34px;[^}]*height:\s*34px;/s,
  );
});

test('10秒操作ボタンは独立した枠線を持たない', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-skip\s*\{[^}]*border:\s*0;/s,
  );
});

test('10秒操作ボタンは円形矢印アイコンで表示する', () => {
  assert.equal((DAILY_HTML.match(/class="audio-skip-icon"/g) || []).length, 2);
  assert.equal((DAILY_HTML.match(/class="audio-skip-arrow"/g) || []).length, 2);
  assert.equal((DAILY_HTML.match(/>10<\/text>/g) || []).length, 2);
  assert.equal((DAILY_HTML.match(/stroke-width="2"/g) || []).length, 2);
  assert.match(DAILY_HTML, /\.audio-skip-number\s*\{[^}]*font-size:\s*11px;/s);
  assert.match(DAILY_HTML, /id="audio-rewind"[^>]*aria-label="10秒巻き戻す"/);
  assert.match(DAILY_HTML, /id="audio-forward"[^>]*aria-label="10秒後送り"/);
});

test('10秒後送りの矢印はSVG全体の中心を軸に反転する', () => {
  assert.match(
    DAILY_HTML,
    /class="audio-skip audio-forward"[\s\S]*?<g class="audio-skip-arrow" transform="translate\(36 0\) scale\(-1 1\)">/,
  );
});
