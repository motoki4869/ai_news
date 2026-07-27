#!/usr/bin/env python3
"""report/*.md を丸ごと変換し、history/reports-data.js を再生成する。
news.html / archive.html の news-card タップ時モーダル表示用データ。
sync-news-html スキルの一手順として、レポート追加のたびに全件再生成する想定。
"""
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REPORT_DIR = REPO_ROOT / "report"
OUT_FILE = REPO_ROOT / "history" / "reports-data.js"


def inline(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    return text


def parse_table(lines: list[str]) -> str:
    rows = [l.strip() for l in lines if l.strip().startswith("|")]
    # 区切り行(|---|---|)を除去
    rows = [r for r in rows if not re.fullmatch(r"\|[\s:\-|]+\|?", r)]
    cells = [[c.strip() for c in r.strip("|").split("|")] for r in rows]
    if not cells:
        return ""
    head, *body = cells
    out = ['<table class="rpt-table">', "<thead><tr>"]
    out += [f"<th>{inline(c)}</th>" for c in head]
    out.append("</tr></thead><tbody>")
    for row in body:
        out.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in row) + "</tr>")
    out.append("</tbody></table>")
    return "".join(out)


def md_to_html(md: str) -> str:
    lines = md.split("\n")
    out = []
    i = 0
    list_buf: list[str] = []

    def flush_list():
        if list_buf:
            out.append("<ul>" + "".join(f"<li>{inline(x)}</li>" for x in list_buf) + "</ul>")
            list_buf.clear()

    while i < len(lines):
        line = lines[i].rstrip()
        stripped = line.strip()

        if not stripped:
            flush_list()
            i += 1
            continue

        if stripped == "---":
            flush_list()
            out.append("<hr>")
            i += 1
            continue

        if stripped.startswith("|"):
            flush_list()
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1
            out.append(parse_table(table_lines))
            continue

        if stripped.startswith("$$"):
            flush_list()
            closing_idx = stripped.find("$$", 2)
            if closing_idx != -1:
                # 開始・終了の $$ が同一行にある単一行formula
                out.append(f'<div class="rpt-formula">$${stripped[2:closing_idx].strip()}$$</div>')
                i += 1
                continue
            formula = [stripped.lstrip("$")]
            i += 1
            while i < len(lines) and "$$" not in lines[i]:
                formula.append(lines[i].strip())
                i += 1
            if i < len(lines):
                formula.append(lines[i].strip().rstrip("$"))
                i += 1
            out.append(f'<div class="rpt-formula">$${"".join(f for f in formula if f)}$$</div>')
            continue

        m = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if m:
            flush_list()
            level = min(len(m.group(1)) + 1, 4)  # 元#1→h2, ##→h2, ###→h3, ####→h4
            if len(m.group(1)) == 1:
                level = 2
            else:
                level = min(len(m.group(1)) + 1, 4)
            out.append(f"<h{level}>{inline(m.group(2))}</h{level}>")
            i += 1
            continue

        if stripped.startswith("- ") or stripped.startswith("* "):
            list_buf.append(stripped[2:].strip())
            i += 1
            continue

        flush_list()
        out.append(f"<p>{inline(stripped)}</p>")
        i += 1

    flush_list()
    return "\n".join(out)


def main():
    data = {}
    for path in sorted(REPORT_DIR.glob("*.md")):
        key = path.stem
        html = md_to_html(path.read_text(encoding="utf-8"))
        data[key] = html

    js = "window.REPORTS = " + json.dumps(data, ensure_ascii=False, indent=2) + ";\n"
    OUT_FILE.write_text(js, encoding="utf-8")
    print(f"generated {OUT_FILE} ({len(data)} reports)")


if __name__ == "__main__":
    main()
