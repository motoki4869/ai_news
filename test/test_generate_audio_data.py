import importlib.util
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "generate_audio_data.py"
SPEC = importlib.util.spec_from_file_location("generate_audio_data", SCRIPT)
generate_audio_data = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generate_audio_data)


class TestExtractDailySection(unittest.TestCase):
    def test_extracts_only_requested_date_section(self):
        markdown = "\n".join([
            "# 2026年8月 AIニュースまとめ",
            "",
            "## 2026-08-27",
            "",
            "- 前日の記事",
            "",
            "## 2026-08-28",
            "",
            "- **今日の記事**: 今日の本文（[出典](https://example.com/today)）。",
            "",
            "## 2026-08-29",
            "",
            "- 翌日の記事",
        ])

        actual = generate_audio_data.extract_daily_section(markdown, "2026-08-28")

        self.assertIn("## 2026-08-28", actual)
        self.assertIn("今日の記事", actual)
        self.assertNotIn("前日の記事", actual)
        self.assertNotIn("翌日の記事", actual)

    def test_raises_when_requested_date_is_missing(self):
        with self.assertRaises(ValueError) as context:
            generate_audio_data.extract_daily_section("## 2026-08-27\n本文", "2026-08-28")

        self.assertIn("2026-08-28", str(context.exception))


class TestBuildAudioData(unittest.TestCase):
    def test_collects_m4a_files_in_date_order_only(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            audio_dir = Path(temp_dir)
            (audio_dir / "2026-08-28.m4a").write_bytes(b"today")
            (audio_dir / "2026-08-27.m4a").write_bytes(b"yesterday")
            (audio_dir / "2026-08-26.mp3").write_bytes(b"ignore")
            (audio_dir / "README.txt").write_text("ignore", encoding="utf-8")

            dates = generate_audio_data.collect_dates_from_dir(audio_dir)
            actual = generate_audio_data.build_audio_data(dates)

        self.assertEqual(list(actual), ["2026-08-27", "2026-08-28"])
        self.assertEqual(actual["2026-08-28"]["src"], "audio/2026-08-28.m4a")
        self.assertEqual(actual["2026-08-28"]["label"], "2026-08-28のAIニュース音声")

    def test_uses_notebooklm_title_when_available(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            audio_dir = Path(temp_dir)
            (audio_dir / "2026-08-28.m4a").write_bytes(b"today")

            dates = generate_audio_data.collect_dates_from_dir(audio_dir)
            actual = generate_audio_data.build_audio_data(
                dates,
                {"2026-08-28": "脱走したAIとローラースケートのアヒル"},
            )

        self.assertEqual(
            actual["2026-08-28"]["title"],
            "脱走したAIとローラースケートのアヒル",
        )

    def test_render_uses_daily_audio_global_and_safe_json(self):
        rendered = generate_audio_data.render_audio_data({
            "2026-08-28": {
                "src": "audio/2026-08-28.m4a",
                "label": "<今日>の\"音声\"",
                "title": "<NotebookLM>の\"タイトル\"",
            }
        })

        self.assertTrue(rendered.startswith("window.DAILY_AUDIO = "))
        self.assertTrue(rendered.endswith(";\n"))
        self.assertNotIn("<今日>", rendered)
        self.assertNotIn("<NotebookLM>", rendered)
        self.assertIn("\\\"音声\\\"", rendered)


if __name__ == "__main__":
    unittest.main()
