#!/usr/bin/env python3
"""当日ニュースのNotebookLMソースと音声一覧を生成する。"""
# launchdはPATHを絞るためpython3が3.9になる。`X | None` 記法を実行時評価させない。
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import sys
from collections.abc import Iterable, Mapping
from pathlib import Path

DATE_HEADER_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
AUDIO_FILE_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})\.m4a$")
DATE_ONLY_RE = re.compile(r"^(\d{4}-\d{2}-\d{2})$")
PLACEHOLDER_AUDIO_TITLES = frozenset({"AIニュース音声"})


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


def load_audio_titles(path: Path | None) -> dict[str, str]:
    """NotebookLMが返した日付別タイトルを読み込む。"""
    if path is None or not path.exists():
        return {}

    value = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(value, dict):
        raise ValueError(f"音声タイトルはJSONオブジェクトで指定してください: {path}")

    titles: dict[str, str] = {}
    for date_str, title in value.items():
        if not isinstance(date_str, str) or not isinstance(title, str):
            continue
        if title.strip():
            _validate_date(date_str)
            titles[date_str] = title.strip()
    return titles


def extract_artifact_title(payload: str, artifact_id: str) -> str:
    """生成済みアーティファクトから正式タイトルだけを取り出す。"""
    try:
        value = json.loads(payload)
    except json.JSONDecodeError:
        return ""

    items = value if isinstance(value, list) else value.get("artifacts", []) if isinstance(value, dict) else []
    for item in items:
        if not isinstance(item, dict):
            continue
        item_id = item.get("id") or item.get("artifact_id")
        title = item.get("title")
        if item_id != artifact_id or not isinstance(title, str):
            continue
        normalized = title.strip()
        if not normalized or normalized in PLACEHOLDER_AUDIO_TITLES:
            return ""
        return normalized
    return ""


def collect_dates_from_dir(audio_dir: Path) -> list[str]:
    """ローカルの音声ディレクトリから日付一覧を取り出す。"""
    if not audio_dir.exists():
        return []
    dates = []
    for path in sorted(audio_dir.iterdir()):
        matched = AUDIO_FILE_RE.match(path.name)
        if matched and path.is_file():
            dates.append(matched.group(1))
    return dates


def collect_dates_from_file(path: Path) -> list[str]:
    """リリースアセット名の一覧（1行1件）から日付一覧を取り出す。

    `2026-08-26.m4a` と `2026-08-26` のどちらの表記も受け付ける。
    """
    dates = []
    for line in path.read_text(encoding="utf-8").splitlines():
        name = line.strip()
        if not name:
            continue
        matched = AUDIO_FILE_RE.match(name) or DATE_ONLY_RE.match(name)
        if matched:
            dates.append(matched.group(1))
    return dates


def build_audio_data(
    dates: Iterable[str],
    titles: Mapping[str, str] | None = None,
    base_url: str | None = None,
) -> dict[str, dict[str, str]]:
    """日付一覧から日付別の再生メタデータを作る。

    base_url を渡すと音声の参照先をその配下（GitHub Releases等）に向ける。
    省略時は日次ページからの相対パス `audio/<日付>.m4a` を使う。
    """
    data: dict[str, dict[str, str]] = {}
    titles = titles or {}
    prefix = base_url.rstrip("/") if base_url else None

    for date_str in dates:
        _validate_date(date_str)
        filename = f"{date_str}.m4a"
        data[date_str] = {
            "src": f"{prefix}/{filename}" if prefix else f"audio/{filename}",
            "label": f"{date_str}のAIニュース音声",
            "title": titles.get(date_str, f"{date_str}のAIニュース音声"),
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
    mode.add_argument("--dates-file", type=Path, help="音声が存在する日付/アセット名の一覧ファイル")
    parser.add_argument("--source-file", type=Path)
    parser.add_argument("--titles-file", type=Path)
    parser.add_argument("--base-url", help="音声の配信元URL（省略時は audio/ 相対パス）")
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
            if args.dates_file:
                dates = collect_dates_from_file(args.dates_file)
            else:
                dates = collect_dates_from_dir(args.audio_dir)
            content = render_audio_data(
                build_audio_data(
                    dates,
                    load_audio_titles(args.titles_file),
                    args.base_url,
                )
            )
        write_atomic(args.output, content)
    except (OSError, ValueError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
