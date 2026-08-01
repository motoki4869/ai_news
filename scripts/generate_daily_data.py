#!/usr/bin/env python3
"""everyday_news/*.md を history/daily-data.js に変換する。

daily.html のカレンダー＋カード表示用データ。
scripts/daily_news_prompt.txt の手順9(commit直前)で毎朝実行される想定。
形式に合わない行を見つけたら stderr に出して終了コード1で落ち、
daily-data.js は書き換えない(壊れた形式で項目を黙って取りこぼさないため)。
"""
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "everyday_news"
OUT_FILE = REPO_ROOT / "history" / "daily-data.js"

DATE_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
ITEM_RE = re.compile(r"^-\s+\*\*(.+?)\*\*[:：]\s*(.+)$")
SOURCE_RE = re.compile(r"[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")


class ParseError(Exception):
    """everyday_news の Markdown が想定形式に一致しないことを表す。"""


def render_inline(text: str) -> str:
    """本文中の **強調** を <strong> に変換する。他のマークアップは扱わない。"""
    return BOLD_RE.sub(r"<strong>\1</strong>", text)


def parse_daily_markdown(text: str, source: str) -> dict:
    """1ファイル分の Markdown を {日付: [項目, ...]} に変換する。

    項目は {"title": str, "body": str, "url": str}。
    想定形式に一致しない行があれば ParseError を送出する。
    """
    result: dict = {}
    current = None

    for lineno, raw in enumerate(text.split("\n"), 1):
        line = raw.strip()

        if not line:
            continue

        # ファイル先頭の「# 2026年8月 AIニュースまとめ」は読み飛ばす
        if line.startswith("# "):
            continue

        matched_date = DATE_RE.match(line)
        if matched_date:
            current = matched_date.group(1)
            result.setdefault(current, [])
            continue

        if line.startswith("- "):
            if current is None:
                raise ParseError(
                    f"{source}:{lineno}: 日付見出し(## YYYY-MM-DD)より前に項目行があります: {line}"
                )
            matched_item = ITEM_RE.match(line)
            if not matched_item:
                raise ParseError(
                    f"{source}:{lineno}: '- **見出し**: 本文' の形式ではありません: {line}"
                )
            title = matched_item.group(1).strip()
            rest = matched_item.group(2).strip()
            matched_src = SOURCE_RE.search(rest)
            if not matched_src:
                raise ParseError(
                    f"{source}:{lineno}: 末尾の（[出典](URL)）が見つかりません: {line}"
                )
            result[current].append(
                {
                    "title": render_inline(title),
                    "body": render_inline(SOURCE_RE.sub("", rest).strip()),
                    "url": matched_src.group(1),
                }
            )
            continue

        raise ParseError(f"{source}:{lineno}: 解釈できない行です: {line}")

    return result


def main() -> int:
    data: dict = {}
    errors: list = []

    for path in sorted(SRC_DIR.glob("*.md")):
        try:
            parsed = parse_daily_markdown(path.read_text(encoding="utf-8"), path.name)
        except ParseError as err:
            errors.append(str(err))
            continue
        for date, items in parsed.items():
            if date in data:
                errors.append(f"{path.name}: 日付 {date} が複数ファイルに重複しています")
                continue
            data[date] = items

    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        print("エラーがあるため history/daily-data.js は更新していません。", file=sys.stderr)
        return 1

    ordered = {date: data[date] for date in sorted(data)}
    js = "window.DAILY_NEWS = " + json.dumps(ordered, ensure_ascii=False, indent=2) + ";\n"
    OUT_FILE.write_text(js, encoding="utf-8")

    item_count = sum(len(v) for v in ordered.values())
    print(f"generated {OUT_FILE} ({len(ordered)} days, {item_count} items)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
