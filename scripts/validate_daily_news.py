#!/usr/bin/env python3
"""当日の日次ニュース件数を検査する。"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path


NEWS_ITEM = re.compile(r"^- \*\*.+\*\*（\[出典\]\(https?://[^)]+\)）\s*$")
SECTION = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})(?:\s.*)?$")


def count_news_items(markdown: str, target_date: str) -> int:
    in_target_section = False
    count = 0
    for line in markdown.splitlines():
        section_match = SECTION.match(line)
        if section_match:
            if in_target_section:
                break
            in_target_section = section_match.group(1) == target_date
            continue
        if in_target_section and NEWS_ITEM.match(line):
            count += 1
    return count


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd(), help="リポジトリのルート")
    parser.add_argument("--date", required=True, help="検査対象の日付 (YYYY-MM-DD)")
    parser.add_argument("--min-items", type=int, default=5, help="必要な最低ニュース件数")
    parser.add_argument("--revision", help="作業ツリーの代わりに検査するGit revision")
    args = parser.parse_args()

    if args.min_items < 1:
        parser.error("--min-items は1以上にしてください")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", args.date):
        parser.error("--date はYYYY-MM-DD形式で指定してください")

    source = args.repo / "everyday_news" / f"{args.date[:4]}{args.date[5:7]}.md"
    try:
        if args.revision:
            result = subprocess.run(
                ["git", "-C", str(args.repo), "show", f"{args.revision}:{source.relative_to(args.repo)}"],
                check=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
            )
            markdown = result.stdout
        else:
            markdown = source.read_text(encoding="utf-8")
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        revision = f" ({args.revision})" if args.revision else ""
        print(f"日次ニュース件数を検査できません{revision}: {source}: {error}", file=sys.stderr)
        return 1

    count = count_news_items(markdown, args.date)
    if count < args.min_items:
        print(
            f"当日分のニュースが最低件数に届きません: {args.date} は{count}件、必要数は{args.min_items}件です。commit・pushを中止します。",
            file=sys.stderr,
        )
        return 1

    revision = f" @ {args.revision}" if args.revision else ""
    print(f"当日分のニュース件数を確認しました: {args.date}{revision} は{count}件 (最低{args.min_items}件)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
