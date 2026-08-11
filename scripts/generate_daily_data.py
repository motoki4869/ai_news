#!/usr/bin/env python3
"""everyday_news/*.md を history/daily-data.js に変換する。

daily.html のカレンダー＋カード表示用データ。
scripts/daily_news_prompt.txt の手順9(commit直前)で毎朝実行される想定。
形式に合わない行を見つけたら stderr に出して終了コード1で落ち、
daily-data.js は書き換えない(壊れた形式で項目を黙って取りこぼさないため)。
"""
import datetime
import json
import os
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "everyday_news"
OUT_FILE = REPO_ROOT / "history" / "daily-data.js"

DATE_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
ITEM_RE = re.compile(r"^-\s+\*\*(.+?)\*\*[:：]\s*(.+)$")
NEW_HEADER_RE = re.compile(r"^-\s+\*\*(.+?)\*\*\s*[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
POINT_RE = re.compile(r"^・\s*\*\*(.+?)\*\*[:：]\s*(.+)$")
SOURCE_RE = re.compile(r"[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")


class ParseError(Exception):
    """everyday_news の Markdown が想定形式に一致しないことを表す。"""


class ParseResult(dict):
    """parse_daily_markdown の戻り値。dict のサブクラスで重複日付情報を保持。"""
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.duplicate_dates = set()


def render_inline(text: str) -> str:
    """本文中の **強調** を <strong> に変換する。他のマークアップは扱わない。"""
    return BOLD_RE.sub(r"<strong>\1</strong>", text)


def parse_daily_markdown(text: str, source: str) -> dict:
    """1ファイル分の Markdown を {日付: [項目, ...]} に変換する。

    項目は {"title": str, "intro": str, "points": list[dict], "url": str}。
    旧形式（1行完結）は points が空リストになる。
    同一ファイル内に同じ日付見出しが複数回現れた場合は、1つの日付にマージする。
    想定形式に一致しない行があれば ParseError を送出する。
    """
    result = ParseResult()
    current_date = None
    current_item = None
    seen_dates = set()

    for lineno, raw in enumerate(text.split("\n"), 1):
        line = raw.strip()

        if not line:
            continue

        # ファイル先頭の「# 2026年8月 AIニュースまとめ」は読み飛ばす
        if line.startswith("# "):
            continue

        matched_date = DATE_RE.match(line)
        if matched_date:
            date_str = matched_date.group(1)
            # 書式だけでなく実在する暦日かどうかも検証する
            # (2026-13-45 や 2026-02-31 がカレンダー表示を壊すため)
            try:
                datetime.date.fromisoformat(date_str)
            except ValueError:
                raise ParseError(
                    f"{source}:{lineno}: 実在しない日付です: {line}"
                )
            current_date = date_str
            current_item = None
            if current_date in seen_dates:
                result.duplicate_dates.add(current_date)
            seen_dates.add(current_date)
            result.setdefault(current_date, [])
            continue

        if line.startswith("・"):
            if current_item is None:
                raise ParseError(
                    f"{source}:{lineno}: 見出し行より前に箇条書き行があります: {line}"
                )
            matched_point = POINT_RE.match(line)
            if not matched_point:
                raise ParseError(
                    f"{source}:{lineno}: '・**ラベル**: 説明' の形式ではありません: {line}"
                )
            current_item["points"].append(
                {
                    "label": render_inline(matched_point.group(1).strip()),
                    "text": render_inline(matched_point.group(2).strip()),
                }
            )
            continue

        if line.startswith("- "):
            if current_date is None:
                raise ParseError(
                    f"{source}:{lineno}: 日付見出し(## YYYY-MM-DD)より前に項目行があります: {line}"
                )

            matched_new_header = NEW_HEADER_RE.match(line)
            if matched_new_header:
                current_item = {
                    "title": matched_new_header.group(1).strip(),
                    "intro": None,
                    "points": [],
                    "url": matched_new_header.group(2),
                    "_lineno": lineno,
                }
                result[current_date].append(current_item)
                continue

            matched_item = ITEM_RE.match(line)
            if not matched_item:
                raise ParseError(
                    f"{source}:{lineno}: '- **見出し**: 本文' または "
                    f"'- **見出し**（[出典](URL)）' の形式ではありません: {line}"
                )
            title = matched_item.group(1).strip()
            rest = matched_item.group(2).strip()
            matched_src = SOURCE_RE.search(rest)
            if not matched_src:
                raise ParseError(
                    f"{source}:{lineno}: 末尾の（[出典](URL)）が見つかりません: {line}"
                )
            current_item = {
                "title": title,
                "intro": render_inline(SOURCE_RE.sub("", rest).strip()),
                "points": [],
                "url": matched_src.group(1),
                "_lineno": lineno,
            }
            result[current_date].append(current_item)
            continue

        # 新形式の見出し行に続く導入文（地の文）
        if current_item is None:
            raise ParseError(f"{source}:{lineno}: 解釈できない行です: {line}")
        rendered = render_inline(line)
        if current_item["intro"] is None:
            current_item["intro"] = rendered
        else:
            current_item["intro"] += " " + rendered

    for date, items in result.items():
        for item in items:
            if item["intro"] is None:
                raise ParseError(
                    f"{source}:{item['_lineno']}: 見出し行の次に導入文がありません: {item['title']}"
                )
            del item["_lineno"]

    return result


def main() -> int:
    data: dict = {}
    errors: list = []
    warnings: list = []

    files = sorted(SRC_DIR.glob("*.md"))
    if not files:
        print(f"エラー: {SRC_DIR} に *.md ファイルが見つかりません", file=sys.stderr)
        print(f"daily-data.js は更新していません。", file=sys.stderr)
        return 1

    for path in files:
        try:
            parsed = parse_daily_markdown(path.read_text(encoding="utf-8"), path.name)
        except ParseError as err:
            errors.append(str(err))
            continue

        # 同一ファイル内の日付重複を警告
        duplicate_dates = getattr(parsed, "duplicate_dates", set())
        for dup_date in sorted(duplicate_dates):
            warnings.append(f"警告: {path.name} で日付 {dup_date} が複数回出現しています（マージします）")

        for date, items in parsed.items():
            if date in data:
                errors.append(f"{path.name}: 日付 {date} が複数ファイルに重複しています")
                continue
            data[date] = items

    # 警告を出力（fatal ではない）
    for warn in warnings:
        print(warn, file=sys.stderr)

    # エラーがあれば終了
    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        print("エラーがあるため history/daily-data.js は更新していません。", file=sys.stderr)
        return 1

    # アトミック書き込み
    ordered = {date: data[date] for date in sorted(data)}
    js = "window.DAILY_NEWS = " + json.dumps(ordered, ensure_ascii=False, indent=2) + ";\n"

    # 一時ファイルに書き込んで、成功後に置き換える
    tmp_file = OUT_FILE.parent / f".{OUT_FILE.name}.tmp"
    try:
        tmp_file.write_text(js, encoding="utf-8")
        os.replace(str(tmp_file), str(OUT_FILE))
    except Exception as e:
        print(f"エラー: ファイル書き込み失敗: {e}", file=sys.stderr)
        if tmp_file.exists():
            tmp_file.unlink()
        return 1

    item_count = sum(len(v) for v in ordered.values())
    print(f"generated {OUT_FILE} ({len(ordered)} days, {item_count} items)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
