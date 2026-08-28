#!/usr/bin/env python3
"""当日ニュースのNotebookLMソースと音声一覧を生成する。"""
import argparse
import datetime
import json
import os
import re
import sys
from pathlib import Path

DATE_HEADER_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
AUDIO_FILE_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})\.m4a$")


def _validate_date(date_str: str) -> None:
    try:
        datetime.date.fromisoformat(date_str)
    except ValueError as error:
        raise ValueError(f"不正な日付です: {date_str}") from error


def extract_daily_section(markdown: str, date_str: str) -> str:
    """Markdownから指定日の見出しを含むセクションだけを切り出す。"""
    _validate_date(date_str)
    lines = markdown.splitlines()
    start = None
    end = len(lines)

    for index, line in enumerate(lines):
        matched = DATE_HEADER_RE.match(line.strip())
        if matched and matched.group(1) == date_str:
            start = index
            break

    if start is None:
        raise ValueError(f"指定日のニュースセクションが見つかりません: {date_str}")

    for index in range(start + 1, len(lines)):
        if DATE_HEADER_RE.match(lines[index].strip()):
            end = index
            break

    section = "\n".join(lines[start:end]).strip()
    return section + "\n"


def build_audio_data(audio_dir: Path) -> dict[str, dict[str, str]]:
    """音声ディレクトリから日付別の再生メタデータを作る。"""
    data: dict[str, dict[str, str]] = {}
    if not audio_dir.exists():
        return data

    for path in sorted(audio_dir.iterdir()):
        matched = AUDIO_FILE_RE.match(path.name)
        if not matched or not path.is_file():
            continue
        date_str = matched.group(1)
        _validate_date(date_str)
        data[date_str] = {
            "src": f"audio/{path.name}",
            "label": f"{date_str}のAIニュース音声",
        }
    return {date: data[date] for date in sorted(data)}


def render_audio_data(data: dict[str, dict[str, str]]) -> str:
    """日次ページから読み込むJavaScriptを生成する。"""
    serialized = json.dumps(data, ensure_ascii=False, indent=2)
    serialized = serialized.replace("<", "\\u003c")
    serialized = serialized.replace(">", "\\u003e")
    serialized = serialized.replace("&", "\\u0026")
    return f"window.DAILY_AUDIO = {serialized};\n"


def write_atomic(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.parent / f".{path.name}.tmp"
    try:
        temporary.write_text(content, encoding="utf-8")
        os.replace(temporary, path)
    except Exception:
        if temporary.exists():
            temporary.unlink()
        raise


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--extract-date", metavar="YYYY-MM-DD")
    mode.add_argument("--audio-dir", type=Path)
    parser.add_argument("--source-file", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    try:
        if args.extract_date:
            if not args.source_file:
                raise ValueError("--extract-date には --source-file が必要です")
            content = extract_daily_section(
                args.source_file.read_text(encoding="utf-8"),
                args.extract_date,
            )
        else:
            content = render_audio_data(build_audio_data(args.audio_dir))
        write_atomic(args.output, content)
    except (OSError, ValueError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
