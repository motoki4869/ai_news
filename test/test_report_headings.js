import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import test from 'node:test';

const REPORT_DIR = path.join(process.cwd(), 'report');

function reportHeadings(filePath) {
  const lines = fs.readFileSync(filePath, 'utf8').split('\n');
  const headings = [];
  let fenced = false;

  for (const line of lines) {
    if (/^```/.test(line)) {
      fenced = !fenced;
      continue;
    }
    if (fenced) continue;

    const match = line.match(/^(#{2,4})\s+(.+)$/);
    if (match) headings.push({ level: match[1].length, title: match[2] });
  }
  return headings;
}

test('全レポートの章・節・小節に階層番号が付いている', () => {
  const files = fs.readdirSync(REPORT_DIR).filter((name) => name.endsWith('.md')).sort();
  assert.ok(files.length > 0);

  for (const file of files) {
    let chapter = 0;
    let section = 0;
    let subsection = 0;

    for (const heading of reportHeadings(path.join(REPORT_DIR, file))) {
      if (heading.level === 2) {
        chapter += 1;
        section = 0;
        subsection = 0;
        assert.match(heading.title, new RegExp(`^${chapter}\\.\\s+`), `${file}: chapter ${chapter}`);
      } else if (heading.level === 3) {
        section += 1;
        subsection = 0;
        assert.match(heading.title, new RegExp(`^${chapter}\\.${section}\\s+`), `${file}: section ${chapter}.${section}`);
      } else {
        subsection += 1;
        assert.match(heading.title, new RegExp(`^${chapter}\\.${section}\\.${subsection}\\s+`), `${file}: subsection ${chapter}.${section}.${subsection}`);
      }
    }
  }
});
