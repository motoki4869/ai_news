#!/usr/bin/env python3
"""docs/glossary.md を変換し、history/glossary-data.js を再生成する。

用語集ページ(history/glossary.html)の描画データ。
用語の追加・修正は docs/glossary.md 側だけを直し、本スクリプトで再生成する。
"""
from __future__ import annotations

import html
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_FILE = REPO_ROOT / "docs" / "glossary.md"
OUT_FILE = REPO_ROOT / "history" / "glossary-data.js"

# 章番号 -> ページ上のテーマ配色クラス
THEME_BY_INDEX = [
    "t-agent", "t-model", "t-physical", "t-infra",
    "t-biz", "t-gov", "t-security", "t-industry", "t-models",
]

SEPARATOR_RE = re.compile(r"\|[\s:\-|]+\|?")
HEADING_RE = re.compile(r"^##\s+(?:(\d+)\.\s*)?(.+)$")


def inline(text: str) -> str:
    """セル内のMarkdown装飾をHTMLへ。エスケープしてから最小限の変換だけ行う。"""
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return text


def parse_table(lines: list[str]) -> tuple[list[str], list[list[str]]]:
    rows = [l.strip() for l in lines if l.strip().startswith("|")]
    rows = [r for r in rows if not SEPARATOR_RE.fullmatch(r)]
    cells = [[c.strip() for c in r.strip("|").split("|")] for r in rows]
    if not cells:
        return [], []
    return cells[0], cells[1:]


def build_sections(md: str) -> list[dict]:
    sections: list[dict] = []
    current: dict | None = None
    buffer: list[str] = []

    def flush() -> None:
        if current is None:
            return
        header, rows = parse_table(buffer)
        buffer.clear()
        if not rows:
            return
        # 9章(モデル名早見表)だけは1列目が開発元なので、見出しにモデル名を出す
        swap = header and header[0].startswith("開発元")
        entries = []
        for row in rows:
            if len(row) < 3:
                continue
            term, sub, desc = (row[1], row[0], row[2]) if swap else (row[0], row[1], row[2])
            if sub in ("—", "-", ""):
                sub = ""
            entries.append({
                "term": inline(term),
                "sub": inline(sub),
                "desc": inline(desc),
                # 検索用: 装飾を落とした素のテキスト
                "q": " ".join(row).replace("**", "").lower(),
            })
        if entries:
            current["entries"] = entries
            sections.append(current)

    for line in md.split("\n"):
        m = HEADING_RE.match(line.rstrip())
        if m:
            flush()
            number, title = m.group(1), m.group(2).strip()
            current = {
                "no": number or "",
                "title": title,
                "theme": THEME_BY_INDEX[len(sections) % len(THEME_BY_INDEX)],
                "id": f"sec{number}" if number else "",
            }
            continue
        if current is not None:
            buffer.append(line)
    flush()
    return sections


def main() -> None:
    md = SRC_FILE.read_text(encoding="utf-8")
    sections = build_sections(md)
    total = sum(len(s["entries"]) for s in sections)
    payload = json.dumps(sections, ensure_ascii=False, indent=2)
    OUT_FILE.write_text(
        "/* 自動生成ファイル — 編集しないこと。\n"
        "   ソース: docs/glossary.md / 生成: scripts/generate_glossary_data.py */\n"
        f"window.GLOSSARY = {payload};\n",
        encoding="utf-8",
    )
    print(f"wrote {OUT_FILE.relative_to(REPO_ROOT)}: {len(sections)} sections / {total} terms")


if __name__ == "__main__":
    main()
