"""generate_daily_data.py のパース処理のテスト。

実行: python3 -m unittest discover -s tests -v
"""
import sys
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from generate_daily_data import ParseError, parse_daily_markdown, render_inline


class TestRenderInline(unittest.TestCase):
    def test_converts_bold_to_strong(self):
        self.assertEqual(render_inline("実に**重要**な話"), "実に<strong>重要</strong>な話")

    def test_leaves_plain_text_untouched(self):
        self.assertEqual(render_inline("ただの文章"), "ただの文章")


class TestParseDailyMarkdown(unittest.TestCase):
    def test_splits_item_into_title_body_and_url(self):
        md = (
            "# 2026年8月 AIニュースまとめ\n"
            "\n"
            "## 2026-08-01\n"
            "\n"
            "- **OpenAI、廉価モデルを値下げ**: 7月30日に最大80%値下げした"
            "（[出典](https://example.com/a)）。\n"
        )
        self.assertEqual(
            parse_daily_markdown(md, "202608.md"),
            {
                "2026-08-01": [
                    {
                        "title": "OpenAI、廉価モデルを値下げ",
                        "body": "7月30日に最大80%値下げした",
                        "url": "https://example.com/a",
                    }
                ]
            },
        )

    def test_keeps_multiple_dates_and_item_order(self):
        md = (
            "# 2026年7月 AIニュースまとめ\n"
            "\n"
            "## 2026-07-05\n"
            "\n"
            "- **一件目**: 本文1（[出典](https://example.com/1)）。\n"
            "- **二件目**: 本文2（[出典](https://example.com/2)）。\n"
            "\n"
            "## 2026-07-09\n"
            "\n"
            "- **三件目**: 本文3（[出典](https://example.com/3)）。\n"
        )
        result = parse_daily_markdown(md, "202607.md")
        self.assertEqual(list(result.keys()), ["2026-07-05", "2026-07-09"])
        self.assertEqual([i["title"] for i in result["2026-07-05"]], ["一件目", "二件目"])
        self.assertEqual(len(result["2026-07-09"]), 1)

    def test_converts_bold_inside_body(self):
        md = (
            "## 2026-08-01\n"
            "- **見出し**: これは**強調**を含む本文（[出典](https://example.com/b)）。\n"
        )
        body = parse_daily_markdown(md, "x.md")["2026-08-01"][0]["body"]
        self.assertEqual(body, "これは<strong>強調</strong>を含む本文")

    def test_raises_when_item_has_no_bold_title(self):
        md = "## 2026-08-01\n- 見出しが太字でない（[出典](https://example.com/c)）。\n"
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("202608.md:2", str(cm.exception))

    def test_raises_when_item_has_no_source_link(self):
        md = "## 2026-08-01\n- **見出し**: 出典のない本文。\n"
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("出典", str(cm.exception))

    def test_raises_on_unrecognized_line(self):
        md = "## 2026-08-01\n本文でも項目でもない地の文\n"
        with self.assertRaises(ParseError):
            parse_daily_markdown(md, "202608.md")

    def test_raises_when_item_appears_before_any_date(self):
        md = "# 2026年8月 AIニュースまとめ\n- **見出し**: 本文（[出典](https://example.com/d)）。\n"
        with self.assertRaises(ParseError):
            parse_daily_markdown(md, "202608.md")


class TestRealData(unittest.TestCase):
    """本番の everyday_news/*.md が例外なくパースできることを保証する回帰テスト。"""

    def test_all_real_files_parse(self):
        src_dir = REPO_ROOT / "everyday_news"
        files = sorted(src_dir.glob("*.md"))
        self.assertTrue(files, "everyday_news/*.md が1件も無い")

        total_days = 0
        total_items = 0
        for path in files:
            parsed = parse_daily_markdown(path.read_text(encoding="utf-8"), path.name)
            total_days += len(parsed)
            total_items += sum(len(v) for v in parsed.values())

        # md 側を直接数えた件数と一致すること
        expected_days = 0
        expected_items = 0
        for path in files:
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.startswith("## "):
                    expected_days += 1
                elif line.startswith("- "):
                    expected_items += 1

        self.assertEqual(total_days, expected_days)
        self.assertEqual(total_items, expected_items)
        self.assertGreaterEqual(total_days, 24)
        self.assertGreaterEqual(total_items, 141)


if __name__ == "__main__":
    unittest.main()
