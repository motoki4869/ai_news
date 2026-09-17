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
