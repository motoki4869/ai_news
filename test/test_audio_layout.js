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
    /grid-template-areas:\s*\n\s*"kicker heard"\s*\n\s*"title\s+title"\s*\n\s*"\.\s+speed"/s,
  );
  assert.match(
    DAILY_HTML,
    /\.audio-speed\s*\{[^}]*grid-area:\s*speed;[^}]*justify-self:\s*end;/s,
  );
});

test('スマホ幅ではListen Toとタイトルの間隔を変えず、速度操作だけ離す', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-copy\s*\{[^}]*align-items:\s*center;\s*\}/s,
  );
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-copy \.audio-speed\s*\{\s*margin-top:\s*14px;/s,
  );
});

test('音声パネルにNotebookLMのサービス名ラベルを表示しない', () => {
  assert.doesNotMatch(DAILY_HTML, /id="audio-label"/);
  assert.doesNotMatch(DAILY_HTML, /audioLabel/);
});

test('iPad幅では速度操作と視聴済みを離して表示する', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-actions\s*\{[^}]*grid-area:\s*actions;[^}]*display:\s*flex;[^}]*gap:\s*28px;/s,
  );
});

test('再生ボタンは44pxのクリック領域で表示する', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-play\s*\{[^}]*width:\s*44px;[^}]*height:\s*44px;/s,
  );
  assert.match(DAILY_HTML, /\.audio-play svg\s*\{[^}]*width:\s*28px;[^}]*height:\s*28px;/s);
});

test('再生ボタンは見た目の円を表示しない', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-play\s*\{[^}]*border:\s*0;[^}]*background:\s*transparent;/s,
  );
  assert.match(
    DAILY_HTML,
    /\.audio-play:hover:not\(:disabled\)\s*\{[^}]*background:\s*transparent;/s,
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
