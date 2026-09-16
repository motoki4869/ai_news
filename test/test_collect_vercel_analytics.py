import csv
import importlib.util
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT_PATH = Path(__file__).parents[1] / "scripts" / "collect_vercel_analytics.py"
SPEC = importlib.util.spec_from_file_location("collect_vercel_analytics", SCRIPT_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class CollectVercelAnalyticsTest(unittest.TestCase):
    def test_build_query_window_uses_previous_day_in_japan_time(self):
        since, until = MODULE.build_query_window("2026-09-16")

        self.assertEqual(since, "2026-09-16T00:00:00+09:00")
        self.assertEqual(until, "2026-09-17T00:00:00+09:00")

    def test_normalize_rows_creates_every_jst_hour_and_fills_missing_hours(self):
        api_rows = [
            {
                "timestamp": "2026-09-15T15:00:00.000Z",
                "visitors": 2,
                "pageviews": 4,
            },
            {
                "timestamp": "2026-09-16T00:00:00.000Z",
                "visitors": 3,
                "pageviews": 7,
            },
        ]

        records = MODULE.normalize_rows("2026-09-16", api_rows)

        self.assertEqual(len(records), 24)
        self.assertEqual(records[0], {
            "date": "2026-09-16",
            "hour_jst": "2026-09-16T00:00:00+09:00",
            "visitors": 2,
            "pageviews": 4,
        })
        self.assertEqual(records[1]["visitors"], 0)
        self.assertEqual(records[9]["visitors"], 3)

    def test_upsert_csv_replaces_existing_day_without_duplicate_rows(self):
        first_records = MODULE.normalize_rows("2026-09-16", [])
        second_records = MODULE.normalize_rows(
            "2026-09-16",
            [{
                "timestamp": "2026-09-16T01:00:00.000Z",
                "visitors": 5,
                "pageviews": 8,
            }],
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "hourly.csv"
            MODULE.upsert_csv(output_path, first_records)
            MODULE.upsert_csv(output_path, second_records)

            with output_path.open(newline="", encoding="utf-8") as file:
                rows = list(csv.DictReader(file))

        self.assertEqual(len(rows), 24)
        self.assertEqual(rows[10]["visitors"], "5")
        self.assertEqual(rows[10]["pageviews"], "8")

    def test_dates_to_collect_retries_yesterday_and_fills_gaps_after_last_record(self):
        dates = MODULE.dates_to_collect(
            "2026-09-16",
            {"2026-09-13", "2026-09-15"},
        )

        self.assertEqual(dates, ["2026-09-14", "2026-09-15"])

    def test_dates_to_collect_starts_with_yesterday_when_no_local_data_exists(self):
        dates = MODULE.dates_to_collect("2026-09-16", set())

        self.assertEqual(dates, ["2026-09-15"])

    def test_collect_pending_does_not_mark_failed_day_as_recorded(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "hourly.csv"
            MODULE.upsert_csv(output_path, MODULE.normalize_rows("2026-09-13", []))

            def fetch_rows(target_date):
                if target_date == "2026-09-14":
                    raise RuntimeError("temporary API failure")
                return []

            with patch.object(MODULE, "_refresh_vercel_cli_session"), patch.object(
                MODULE, "fetch_rows", side_effect=fetch_rows
            ):
                result = MODULE.collect_pending("2026-09-16", output_path)

            recorded_dates = MODULE.read_recorded_dates(output_path)

        self.assertEqual(result, 1)
        self.assertNotIn("2026-09-14", recorded_dates)
        self.assertIn("2026-09-15", recorded_dates)

    def test_collect_pending_retries_a_failed_day_on_the_next_run(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            output_path = Path(temp_dir) / "hourly.csv"
            MODULE.upsert_csv(output_path, MODULE.normalize_rows("2026-09-13", []))

            def fail_first_then_succeed(target_date):
                if target_date == "2026-09-14" and not hasattr(fail_first_then_succeed, "failed"):
                    fail_first_then_succeed.failed = True
                    raise RuntimeError("temporary API failure")
                return []

            with patch.object(MODULE, "_refresh_vercel_cli_session"), patch.object(
                MODULE, "fetch_rows", side_effect=fail_first_then_succeed
            ):
                self.assertEqual(MODULE.collect_pending("2026-09-16", output_path), 1)
                self.assertIn("2026-09-14", MODULE.read_pending_dates(output_path))
                self.assertEqual(MODULE.collect_pending("2026-09-16", output_path), 0)

            self.assertNotIn("2026-09-14", MODULE.read_pending_dates(output_path))


if __name__ == "__main__":
    unittest.main()
