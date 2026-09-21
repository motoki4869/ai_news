#!/usr/bin/env python3
"""docs/glossary.md を変換し、history/glossary-data.js を再生成する。

用語集ページ(history/glossary.html)の描画データ。
用語の追加・修正は docs/glossary.md 側だけを直し、本スクリプトで再生成する。
"""
from __future__ import annotations

import html
import json
import os
import re
import stat
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_FILE = REPO_ROOT / "docs" / "glossary.md"
OUT_FILE = REPO_ROOT / "history" / "glossary-data.js"

# 章番号 -> ページ上のテーマ配色クラス
THEME_BY_INDEX = [
    "t-agent", "t-model", "t-physical", "t-infra",
    "t-biz", "t-gov", "t-security", "t-industry", "t-models",
]

HEADING_RE = re.compile(r"^##\s+(?:(\d+)\.\s*)?(.+)$")
SEPARATOR_CELL_RE = re.compile(r"^:?-{3,}:?$")
STANDARD_HEADER = ("用語", "正式名称 / 読み", "意味")
MODEL_HEADER = ("開発元", "モデル / シリーズ", "補足")


class GlossaryParseError(ValueError):
    """用語集Markdownの表が想定形式に一致しないことを表す。"""


def inline(text: str) -> str:
    """セル内のMarkdown装飾をHTMLへ。エスケープしてから最小限の変換だけ行う。"""
    text = html.escape(text)
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"`(.+?)`", r"<code>\1</code>", text)
    return text


def _table_cells(line: str) -> list[str]:
    return [cell.strip() for cell in line.strip().strip("|").split("|")]


def _is_separator(cells: list[str]) -> bool:
    return bool(cells) and all(SEPARATOR_CELL_RE.fullmatch(cell) for cell in cells)


def parse_table(lines: list[tuple[int, str]]) -> tuple[list[str], list[list[str]]]:
    rows = [(lineno, line.strip()) for lineno, line in lines if line.strip().startswith("|")]
    if not rows:
        return [], []

    header_lineno, header_line = rows[0]
    header = _table_cells(header_line)
    expected_headers = (STANDARD_HEADER, MODEL_HEADER)
    if tuple(header) not in expected_headers:
        raise GlossaryParseError(
            f"{SRC_FILE}:{header_lineno}: 用語集の表見出しが不正です: {header_line}"
        )
    if len(rows) < 2 or not _is_separator(_table_cells(rows[1][1])):
        lineno = rows[1][0] if len(rows) > 1 else header_lineno
        raise GlossaryParseError(
            f"{SRC_FILE}:{lineno}: 用語集の表に区切り行がありません"
        )

    data: list[list[str]] = []
    for lineno, line in rows[2:]:
        cells = _table_cells(line)
        if _is_separator(cells):
            raise GlossaryParseError(
                f"{SRC_FILE}:{lineno}: 表のデータ行に区切り行があります: {line}"
            )
        if len(cells) != 3:
            raise GlossaryParseError(
                f"{SRC_FILE}:{lineno}: 用語集の表は3列必要です（{len(cells)}列）: {line}"
            )
        if not cells[0] or not cells[2]:
            raise GlossaryParseError(
                f"{SRC_FILE}:{lineno}: 用語集の表の必須セルが空です: {line}"
            )
        data.append(cells)
    return header, data


def build_sections(md: str) -> list[dict]:
    sections: list[dict] = []
    current: dict | None = None
    buffer: list[tuple[int, str]] = []

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

    for lineno, line in enumerate(md.split("\n"), 1):
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
            buffer.append((lineno, line))
    flush()
    return sections


def write_output(path: Path, content: str) -> None:
    """生成物を一時ファイルへ書いてから原子的に置換する。"""
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        output_mode = stat.S_IMODE(path.stat().st_mode)
    except FileNotFoundError:
        output_mode = 0o644
    temp_path: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=path.parent,
            prefix=f".{path.name}.",
            delete=False,
        ) as temp_file:
            temp_path = temp_file.name
            temp_file.write(content)
            temp_file.flush()
            os.fsync(temp_file.fileno())
        os.chmod(temp_path, output_mode)
        os.replace(temp_path, path)
        temp_path = None
    finally:
        if temp_path is not None:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass


def main() -> int:
    md = SRC_FILE.read_text(encoding="utf-8")
    try:
        sections = build_sections(md)
    except GlossaryParseError as exc:
        print(f"エラー: {exc}", file=sys.stderr)
        print("history/glossary-data.js は更新していません。", file=sys.stderr)
        return 1
    total = sum(len(s["entries"]) for s in sections)
    payload = json.dumps(sections, ensure_ascii=False, indent=2)
    write_output(
        OUT_FILE,
        "/* 自動生成ファイル — 編集しないこと。\n"
        "   ソース: docs/glossary.md / 生成: scripts/generate_glossary_data.py */\n"
        f"window.GLOSSARY = {payload};\n",
    )
    print(f"wrote {OUT_FILE.relative_to(REPO_ROOT)}: {len(sections)} sections / {total} terms")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
