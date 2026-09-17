const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const DAILY_HTML = fs.readFileSync(
  path.join(__dirname, '..', 'history', 'daily.html'),
  'utf8',
);

test('スマホ幅では再生速度を上段右、視聴済みをタイトル行右に表示する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-copy\s*\{[^}]*grid-template-areas:\s*\n\s*"kicker \."\s*\n\s*"title\s+heard"/s,
  );
  assert.match(
    DAILY_HTML,
    /\.audio-speed\s*\{[^}]*grid-area:\s*speed;[^}]*justify-self:\s*end;/s,
  );
  assert.match(
    DAILY_HTML,
    /\.audio-heard-label\s*\{[^}]*grid-area:\s*heard;[^}]*justify-self:\s*end;/s,
  );
});

test('スマホ幅ではListen Toとタイトルの間隔を変えず、速度操作を上段右に置く', () => {
  assert.match(
    DAILY_HTML,
    /\.audio-copy\s*\{[^}]*align-items:\s*center;\s*\}/s,
  );
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-copy \.audio-speed\s*\{[^}]*position:\s*absolute;[^}]*top:\s*0;[^}]*right:\s*0;/s,
  );
});

test('スマホ幅では視聴済みの文言を隠し、タイトルをチェックボックスの手前まで1行で表示する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-heard-label span\s*\{\s*display:\s*none;\s*\}/s,
  );
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-copy h3\s*\{[^}]*min-width:\s*0;[^}]*white-space:\s*nowrap;[^}]*overflow:\s*visible;/s,
  );
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-speed\s*\{[^}]*position:\s*absolute;[^}]*right:\s*0;/s,
  );
});

test('スマホ幅ではタイトル行との間隔と視聴済みの縦位置を調整する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-copy\s*\{[^}]*row-gap:\s*8px;/s,
  );
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-heard-label\s*\{[^}]*transform:\s*translateY\(2px\);/s,
  );
});

test('スマホ幅でも再生操作を再生バーの左側に並べる', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-btn-row\s*\{[^}]*flex:\s*0 0 auto;[^}]*order:\s*-1;[^}]*\}[\s\S]*?\.audio-seek-row\s*\{\s*flex:\s*1 1 auto;/s,
  );
});

test('スマホ幅では操作列を詰めて再生バーの長さを確保する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-ui\s*\{[^}]*flex-wrap:\s*nowrap;[^}]*column-gap:\s*0;[\s\S]*?\.audio-btn-row\s*\{[^}]*gap:\s*0;[\s\S]*?\.audio-seek-row\s*\{[^}]*flex:\s*1 1 auto;[^}]*gap:\s*6px;[\s\S]*?\.audio-time\s*\{[^}]*min-width:\s*30px;/s,
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

test('スマホ幅では再生と10秒操作のアイコンだけを縮小する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-play svg\s*\{\s*width:\s*22px;\s*height:\s*22px;\s*\}[\s\S]*?\.audio-skip-icon\s*\{\s*width:\s*28px;\s*height:\s*28px;/s,
  );
  assert.match(DAILY_HTML, /\.audio-play\s*\{[^}]*width:\s*44px;[^}]*height:\s*44px;/s);
  assert.match(DAILY_HTML, /\.audio-skip\s*\{[^}]*width:\s*44px;[^}]*height:\s*44px;/s);
});

test('スマホ幅では操作列を左へ寄せて再生バーを広げる', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-ui\s*\{[^}]*column-gap:\s*0;[\s\S]*?\.audio-btn-row\s*\{[^}]*margin-left:\s*-8px;[^}]*margin-right:\s*-8px;[\s\S]*?\.audio-seek-row\s*\{[^}]*gap:\s*6px;[\s\S]*?\.audio-time\s*\{[^}]*min-width:\s*30px;/s,
  );
});

test('スマホ幅では操作ボタンを詰め、再生バーとの間隔を確保する', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-play,\s*\.audio-skip\s*\{\s*width:\s*36px;\s*height:\s*36px;\s*\}[\s\S]*?\.audio-seek-row\s*\{[^}]*margin-left:\s*20px;/s,
  );
});

test('スマホ幅では10秒送りと再生時間の間隔を広げる', () => {
  assert.match(
    DAILY_HTML,
    /@media\s*\(max-width:\s*768px\)[\s\S]*?\.audio-seek-row\s*\{[^}]*margin-left:\s*20px;/s,
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
