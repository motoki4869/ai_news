#!/usr/bin/env python3
"""前日のVercel Web Analyticsを1時間単位でローカル保存する。"""

import argparse
import csv
import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from zoneinfo import ZoneInfo


REPO_DIR = Path(__file__).resolve().parents[1]
DEFAULT_OUTPUT = REPO_DIR / "data" / "analytics" / "vercel_web_analytics_hourly.csv"
PROJECT_ID = "prj_o9pZRLJOhe8AxKFuuSJ5fej58OUw"
TEAM_ID = "team_9oDHLjpQ8KPeMUuqsGmUeTin"
API_URL = "https://api.vercel.com/v1/query/web-analytics/visits/aggregate"
JST = ZoneInfo("Asia/Tokyo")
UTC = timezone.utc
CSV_FIELDS = ["date", "hour_jst", "visitors", "pageviews"]
MAX_BACKFILL_DAYS = 30


def build_query_window(target_date: str) -> Tuple[str, str]:
    """対象日の日本時間0時から翌日0時までのAPI検索範囲を返す。"""
    day = date.fromisoformat(target_date)
    next_day = day + timedelta(days=1)
    return (
        f"{day.isoformat()}T00:00:00+09:00",
        f"{next_day.isoformat()}T00:00:00+09:00",
    )


def _parse_timestamp(value: str) -> datetime:
    normalized = value.replace("Z", "+00:00")
    parsed = datetime.fromisoformat(normalized)
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=UTC)
    return parsed


def normalize_rows(target_date: str, api_rows: List[Dict[str, object]]) -> List[Dict[str, object]]:
    """APIの行を、日本時間の対象日24時間分のCSV行へ整形する。"""
    values: Dict[str, Tuple[int, int]] = {}
    for row in api_rows:
        timestamp = row.get("timestamp")
        if not isinstance(timestamp, str):
            continue
        hour = _parse_timestamp(timestamp).astimezone(JST).replace(
            minute=0, second=0, microsecond=0
        )
        if hour.date().isoformat() != target_date:
            continue
        values[hour.isoformat()] = (
            int(row.get("visitors", 0) or 0),
            int(row.get("pageviews", 0) or 0),
        )

    start = datetime.combine(date.fromisoformat(target_date), datetime.min.time(), JST)
    records: List[Dict[str, object]] = []
    for offset in range(24):
        hour = start + timedelta(hours=offset)
        hour_key = hour.isoformat()
        visitors, pageviews = values.get(hour_key, (0, 0))
        records.append({
            "date": target_date,
            "hour_jst": hour_key,
            "visitors": visitors,
            "pageviews": pageviews,
        })
    return records


def upsert_csv(output_path: Path, records: List[Dict[str, object]]) -> None:
    """対象日の行を置き換え、他の日の記録は残す。"""
    target_dates = {str(record["date"]) for record in records}
    existing: List[Dict[str, str]] = []
    if output_path.exists():
        with output_path.open(newline="", encoding="utf-8") as file:
            existing = [row for row in csv.DictReader(file) if row.get("date") not in target_dates]

    merged = existing + [{field: str(record[field]) for field in CSV_FIELDS} for record in records]
    merged.sort(key=lambda row: row["hour_jst"])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CSV_FIELDS)
        writer.writeheader()
        writer.writerows(merged)


def read_recorded_dates(output_path: Path) -> Set[str]:
    """24時間分の行が揃っている日付だけを、取得済みとして返す。"""
    if not output_path.exists():
        return set()
    counts: Dict[str, int] = {}
    with output_path.open(newline="", encoding="utf-8") as file:
        for row in csv.DictReader(file):
            target_date = row.get("date")
            if target_date:
                counts[target_date] = counts.get(target_date, 0) + 1
    return {target_date for target_date, count in counts.items() if count >= 24}


def _pending_path(output_path: Path) -> Path:
    return output_path.with_name(f"{output_path.stem}.pending.json")


def read_pending_dates(output_path: Path) -> Set[str]:
    """前回の実行で失敗し、次回に再試行する日付を返す。"""
    pending_path = _pending_path(output_path)
    if not pending_path.exists():
        return set()
    try:
        with pending_path.open(encoding="utf-8") as file:
            values = json.load(file)
    except (OSError, ValueError) as error:
        raise RuntimeError("Analyticsの再試行情報を読み込めませんでした。") from error
    if not isinstance(values, list):
        raise RuntimeError("Analyticsの再試行情報の形式が想定と異なります。")
    pending: Set[str] = set()
    for value in values:
        if not isinstance(value, str):
            continue
        try:
            date.fromisoformat(value)
        except ValueError:
            continue
        pending.add(value)
    return pending


def write_pending_dates(output_path: Path, pending_dates: Set[str]) -> None:
    pending_path = _pending_path(output_path)
    pending_path.parent.mkdir(parents=True, exist_ok=True)
    with pending_path.open("w", encoding="utf-8") as file:
        json.dump(sorted(pending_dates), file, ensure_ascii=False, indent=2)
        file.write("\n")


def dates_to_collect(current_date: str, recorded_dates: Set[str]) -> List[str]:
    """前日を必ず含め、初回記録日以降の未取得日を最大30日分返す。"""
    yesterday = date.fromisoformat(current_date) - timedelta(days=1)
    existing_days = sorted(
        date.fromisoformat(target_date)
        for target_date in recorded_dates
        if date.fromisoformat(target_date) <= yesterday
    )
    if not existing_days:
        return [yesterday.isoformat()]

    earliest = max(existing_days[0], yesterday - timedelta(days=MAX_BACKFILL_DAYS - 1))
    targets: List[str] = []
    day = earliest
    while day <= yesterday:
        target_date = day.isoformat()
        if target_date == yesterday.isoformat() or target_date not in recorded_dates:
            targets.append(target_date)
        day += timedelta(days=1)
    return targets


def _find_vercel_binary() -> Optional[str]:
    configured = os.environ.get("VERCEL_BIN")
    if configured and Path(configured).is_file():
        return configured
    found = shutil.which("vercel")
    if found:
        return found
    for candidate in (
        "/opt/homebrew/bin/vercel",
        "/usr/local/bin/vercel",
        "/Users/motoki/.volta/bin/vercel",
    ):
        if Path(candidate).is_file():
            return candidate
    return None


def _refresh_vercel_cli_session() -> None:
    """Vercel CLIのrefresh tokenを使い、期限切れ前に認証状態を更新する。"""
    binary = _find_vercel_binary()
    if not binary:
        return
    environment = os.environ.copy()
    environment["VERCEL_DISABLE_UPDATE_CHECK"] = "1"
    try:
        subprocess.run(
            [binary, "whoami"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
            timeout=30,
            env=environment,
        )
    except (OSError, subprocess.SubprocessError):
        # 既存のアクセストークンが有効なら、API取得はそのまま試みる。
        pass


def _load_vercel_token() -> str:
    token = os.environ.get("VERCEL_TOKEN")
    if token:
        return token

    auth_path = Path.home() / "Library" / "Application Support" / "com.vercel.cli" / "auth.json"
    try:
        with auth_path.open(encoding="utf-8") as file:
            auth = json.load(file)
        token = auth.get("token")
    except (OSError, ValueError) as error:
        raise RuntimeError("Vercel CLIの認証情報を読み込めませんでした。vercel loginを確認してください。") from error
    if not token:
        raise RuntimeError("Vercel CLIのログインが必要です。vercel loginを実行してください。")
    return str(token)


def fetch_rows(target_date: str) -> List[Dict[str, object]]:
    since, until = build_query_window(target_date)
    query = urllib.parse.urlencode({
        "projectId": PROJECT_ID,
        "teamId": TEAM_ID,
        "since": since,
        "until": until,
        "by": "hour",
        "limit": 100,
    })
    request = urllib.request.Request(
        f"{API_URL}?{query}",
        headers={"Authorization": f"Bearer {_load_vercel_token()}"},
    )
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        raise RuntimeError(f"Vercel Analytics APIの取得に失敗しました（HTTP {error.code}）。") from error
    except (urllib.error.URLError, TimeoutError, ValueError) as error:
        raise RuntimeError("Vercel Analytics APIの取得に失敗しました。") from error

    rows = payload.get("data", [])
    if not isinstance(rows, list):
        raise RuntimeError("Vercel Analytics APIの応答形式が想定と異なります。")
    return rows


def _save_day(target_date: str, output_path: Path) -> Tuple[int, int]:
    records = normalize_rows(target_date, fetch_rows(target_date))
    upsert_csv(output_path, records)
    total_visitors = sum(int(record["visitors"]) for record in records)
    total_pageviews = sum(int(record["pageviews"]) for record in records)
    return total_visitors, total_pageviews


def collect(target_date: str, output_path: Path) -> int:
    _refresh_vercel_cli_session()
    total_visitors, total_pageviews = _save_day(target_date, output_path)
    print(
        f"Vercel Analyticsを保存しました: {target_date} "
        f"(Visitors合計={total_visitors}, Page Views合計={total_pageviews})"
    )
    return 0


def collect_pending(current_date: str, output_path: Path) -> int:
    current_day = date.fromisoformat(current_date)
    yesterday = current_day - timedelta(days=1)
    oldest_allowed = yesterday - timedelta(days=MAX_BACKFILL_DAYS - 1)
    pending_dates = {
        target_date
        for target_date in read_pending_dates(output_path)
        if oldest_allowed <= date.fromisoformat(target_date) <= yesterday
    }
    pending_dates.update(dates_to_collect(current_date, read_recorded_dates(output_path)))
    write_pending_dates(output_path, pending_dates)
    _refresh_vercel_cli_session()
    failures: List[str] = []
    for target_date in sorted(pending_dates):
        try:
            total_visitors, total_pageviews = _save_day(target_date, output_path)
            pending_dates.remove(target_date)
            write_pending_dates(output_path, pending_dates)
            print(
                f"Vercel Analyticsを保存しました: {target_date} "
                f"(Visitors合計={total_visitors}, Page Views合計={total_pageviews})"
            )
        except RuntimeError as error:
            failures.append(f"{target_date}: {error}")

    if failures:
        for failure in failures:
            print(f"エラー: {failure}", file=sys.stderr)
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--date", help="取得対象日 (YYYY-MM-DD)。指定時はその日だけ取得")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT, help="保存先CSV")
    args = parser.parse_args()
    try:
        if args.date:
            date.fromisoformat(args.date)
            return collect(args.date, args.output)
        return collect_pending(datetime.now(JST).date().isoformat(), args.output)
    except (ValueError, RuntimeError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
