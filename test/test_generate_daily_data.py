"""generate_daily_data.py のパース処理のテスト。

実行: python3 -m unittest discover -s tests -v
"""
import contextlib
import io
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT / "scripts"))

from generate_daily_data import ParseError, parse_daily_markdown, render_inline, main


class TestRenderInline(unittest.TestCase):
    def test_converts_bold_to_strong(self):
        self.assertEqual(render_inline("実に**重要**な話"), "実に<strong>重要</strong>な話")

    def test_leaves_plain_text_untouched(self):
        self.assertEqual(render_inline("ただの文章"), "ただの文章")


class TestParseDailyMarkdown(unittest.TestCase):
    def test_splits_item_into_title_intro_points_and_url(self):
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
                        "intro": "7月30日に最大80%値下げした",
                        "points": [],
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

    def test_converts_bold_inside_intro(self):
        md = (
            "## 2026-08-01\n"
            "- **見出し**: これは**強調**を含む本文（[出典](https://example.com/b)）。\n"
        )
        intro = parse_daily_markdown(md, "x.md")["2026-08-01"][0]["intro"]
        self.assertEqual(intro, "これは<strong>強調</strong>を含む本文")

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

    def test_title_is_not_rendered_as_strong(self):
        """title には render_inline を適用しない（daily.html が textContent で描画するため）"""
        md = (
            "## 2026-08-01\n"
            "- **A**と**B**: 本文です（[出典](https://example.com/a)）。\n"
        )
        item = parse_daily_markdown(md, "202608.md")["2026-08-01"][0]
        self.assertNotIn("<strong>", item["title"])

    def test_raises_on_invalid_calendar_date(self):
        """書式は正しくても実在しない暦日なら ParseError"""
        md = "## 2026-02-30\n- **見出し**: 本文（[出典](https://example.com/a)）。\n"
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202602.md")
        self.assertIn("実在しない日付", str(cm.exception))

    def test_parses_new_format_header_intro_and_points(self):
        md = (
            "## 2026-08-12\n"
            "- **【事件の裏側】三大巨頭の自律ハック事件、実は単一設定エラーだったことが判明**"
            "（[出典](https://example.com/new)）\n"
            "  本日未明、三社が共同声明を発表し原因が確定した。\n"
            "  ・**背景**: 数週間前から兆候があった。\n"
            "  ・**影響**: 業界全体の監査体制が見直される。\n"
        )
        item = parse_daily_markdown(md, "202608.md")["2026-08-12"][0]
        self.assertEqual(
            item,
            {
                "title": "【事件の裏側】三大巨頭の自律ハック事件、実は単一設定エラーだったことが判明",
                "intro": "本日未明、三社が共同声明を発表し原因が確定した。",
                "points": [
                    {"label": "背景", "text": "数週間前から兆候があった。"},
                    {"label": "影響", "text": "業界全体の監査体制が見直される。"},
                ],
                "url": "https://example.com/new",
            },
        )

    def test_new_format_intro_can_span_two_lines(self):
        md = (
            "## 2026-08-12\n"
            "- **見出し**（[出典](https://example.com/x)）\n"
            "  1行目の導入文。\n"
            "  2行目に続く導入文。\n"
            "  ・**ラベル**: 説明。\n"
        )
        item = parse_daily_markdown(md, "202608.md")["2026-08-12"][0]
        self.assertEqual(item["intro"], "1行目の導入文。 2行目に続く導入文。")

    def test_new_format_and_old_format_items_share_same_date(self):
        md = (
            "## 2026-08-12\n"
            "- **旧形式**: 本文（[出典](https://example.com/old)）。\n"
            "- **新形式**（[出典](https://example.com/new)）\n"
            "  導入文。\n"
            "  ・**ラベル**: 説明。\n"
        )
        items = parse_daily_markdown(md, "202608.md")["2026-08-12"]
        self.assertEqual(items[0]["points"], [])
        self.assertEqual(items[1]["points"], [{"label": "ラベル", "text": "説明。"}])

    def test_new_format_title_is_not_rendered_as_strong(self):
        md = (
            "## 2026-08-12\n"
            "- **【A】と【B】**（[出典](https://example.com/x)）\n"
            "  導入文。\n"
        )
        item = parse_daily_markdown(md, "202608.md")["2026-08-12"][0]
        self.assertNotIn("<strong>", item["title"])

    def test_raises_when_point_line_before_any_item(self):
        md = "## 2026-08-12\n  ・**ラベル**: 説明。\n"
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("202608.md:2", str(cm.exception))

    def test_raises_when_point_line_is_malformed(self):
        md = (
            "## 2026-08-12\n"
            "- **見出し**（[出典](https://example.com/x)）\n"
            "  導入文。\n"
            "  ・ラベルが太字でない: 説明。\n"
        )
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("・**ラベル**", str(cm.exception))

    def test_raises_when_new_format_header_has_no_intro(self):
        md = (
            "## 2026-08-12\n"
            "- **見出し**（[出典](https://example.com/x)）\n"
            "  ・**ラベル**: 説明。\n"
        )
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("導入文", str(cm.exception))

    def test_old_format_line_ending_in_bold_is_not_misparsed_as_new_header(self):
        """本文末尾が**強調**で終わる旧形式行は、NEW_HEADER_RE に誤マッチせず
        ITEM_RE 側で旧形式として正しくパースされること（Important Issue 1 回帰）。"""
        md = (
            "## 2026-08-01\n"
            "- **見出し**: 本文の**強調**（[出典](https://example.com/a)）。\n"
        )
        item = parse_daily_markdown(md, "202608.md")["2026-08-01"][0]
        self.assertEqual(
            item,
            {
                "title": "見出し",
                "intro": "本文の<strong>強調</strong>",
                "points": [],
                "url": "https://example.com/a",
            },
        )

    def test_raises_when_intro_continues_past_two_lines(self):
        """新形式の導入文が2行を超えて続く場合は ParseError（Important Issue 2 回帰）。"""
        md = (
            "## 2026-08-12\n"
            "- **見出し**（[出典](https://example.com/x)）\n"
            "  1行目の導入文。\n"
            "  2行目に続く導入文。\n"
            "  3行目は許されない地の文。\n"
        )
        with self.assertRaises(ParseError) as cm:
            parse_daily_markdown(md, "202608.md")
        self.assertIn("導入文は2行までです", str(cm.exception))


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
        # 日付は unique で数える（同一ファイル内に同じ日付見出しが複数回現れることがあるため）
        expected_days_unique = set()
        expected_items = 0
        for path in files:
            for line in path.read_text(encoding="utf-8").splitlines():
                if line.startswith("## "):
                    # YYYY-MM-DD 形式の日付を抽出
                    parts = line.split()
                    if len(parts) >= 2:
                        expected_days_unique.add(parts[1])
                elif line.startswith("- "):
                    expected_items += 1

        self.assertEqual(total_days, len(expected_days_unique))
        self.assertEqual(total_items, expected_items)
        self.assertGreaterEqual(total_days, 24)
        self.assertGreaterEqual(total_items, 141)


class TestMain(unittest.TestCase):
    """main() 関数の安全性テスト"""

    def test_main_with_no_input_files(self):
        """入力ファイル0件時は exit 1 で出力ファイルを書き換えない"""
        with tempfile.TemporaryDirectory() as tmpdir:
            src_dir = Path(tmpdir) / "empty_news"
            src_dir.mkdir()
            out_file = Path(tmpdir) / "output.js"
            out_file.write_text("old content")

            with mock.patch("generate_daily_data.SRC_DIR", src_dir):
                with mock.patch("generate_daily_data.OUT_FILE", out_file):
                    # stdout/stderr をキャプチャ
                    stdout_buf = io.StringIO()
                    stderr_buf = io.StringIO()
                    with contextlib.redirect_stdout(stdout_buf):
                        with contextlib.redirect_stderr(stderr_buf):
                            result = main()

            self.assertEqual(result, 1)
            self.assertEqual(out_file.read_text(), "old content")

    def test_main_with_duplicate_dates_across_files(self):
        """ファイル間で日付が重複時は exit 1 で出力ファイルを書き換えない"""
        with tempfile.TemporaryDirectory() as tmpdir:
            src_dir = Path(tmpdir) / "news"
            src_dir.mkdir()
            out_file = Path(tmpdir) / "output.js"
            out_file.write_text("old content")

            # 同じ日付を持つ2つのファイルを作成
            (src_dir / "file1.md").write_text(
                "## 2026-08-01\n- **News1**: text1（[出典](https://example.com/1)）。\n",
                encoding="utf-8"
            )
            (src_dir / "file2.md").write_text(
                "## 2026-08-01\n- **News2**: text2（[出典](https://example.com/2)）。\n",
                encoding="utf-8"
            )

            with mock.patch("generate_daily_data.SRC_DIR", src_dir):
                with mock.patch("generate_daily_data.OUT_FILE", out_file):
                    # stdout/stderr をキャプチャ
                    stdout_buf = io.StringIO()
                    stderr_buf = io.StringIO()
                    with contextlib.redirect_stdout(stdout_buf):
                        with contextlib.redirect_stderr(stderr_buf):
                            result = main()

            self.assertEqual(result, 1)
            self.assertEqual(out_file.read_text(), "old content")

    def test_main_with_duplicate_dates_within_file(self):
        """ファイル内で日付が重複時は exit 0 で警告を出力、項目はマージ"""
        with tempfile.TemporaryDirectory() as tmpdir:
            src_dir = Path(tmpdir) / "news"
            src_dir.mkdir()
            out_file = Path(tmpdir) / "output.js"

            # 同じ日付が2回現れるファイル
            (src_dir / "news.md").write_text(
                "## 2026-08-01\n"
                "- **News1**: text1（[出典](https://example.com/1)）。\n"
                "## 2026-08-01\n"
                "- **News2**: text2（[出典](https://example.com/2)）。\n",
                encoding="utf-8"
            )

            with mock.patch("generate_daily_data.SRC_DIR", src_dir):
                with mock.patch("generate_daily_data.OUT_FILE", out_file):
                    # stdout/stderr をキャプチャして警告を検証
                    stdout_buf = io.StringIO()
                    stderr_buf = io.StringIO()
                    with contextlib.redirect_stdout(stdout_buf):
                        with contextlib.redirect_stderr(stderr_buf):
                            result = main()
                    stderr_output = stderr_buf.getvalue()

            self.assertEqual(result, 0)
            # 警告メッセージが出力されていること
            self.assertIn("警告:", stderr_output)
            self.assertIn("news.md", stderr_output)
            self.assertIn("2026-08-01", stderr_output)
            self.assertIn("複数回出現", stderr_output)

            # ファイルが作成されていること
            self.assertTrue(out_file.exists())
            content = out_file.read_text()
            self.assertIn("window.DAILY_NEWS", content)
            # 両方のニュースが含まれていること
            self.assertIn("News1", content)
            self.assertIn("News2", content)
            # 1日分のデータとして扱われていること（JSON内に1つの日付キーがあること）
            import json
            js_content = content.replace("window.DAILY_NEWS = ", "").strip()
            if js_content.endswith(";"):
                js_content = js_content[:-1]
            data = json.loads(js_content)
            self.assertEqual(len(data), 1)
            self.assertEqual(len(data["2026-08-01"]), 2)

    def test_main_success_case(self):
        """正常系：出力ファイルが正しく生成される"""
        with tempfile.TemporaryDirectory() as tmpdir:
            src_dir = Path(tmpdir) / "news"
            src_dir.mkdir()
            out_file = Path(tmpdir) / "output.js"

            (src_dir / "news.md").write_text(
                "# 2026年8月 AIニュースまとめ\n"
                "## 2026-08-01\n"
                "- **NewsA**: textA（[出典](https://example.com/a)）。\n"
                "## 2026-08-02\n"
                "- **NewsB**: textB（[出典](https://example.com/b)）。\n",
                encoding="utf-8"
            )

            with mock.patch("generate_daily_data.SRC_DIR", src_dir):
                with mock.patch("generate_daily_data.OUT_FILE", out_file):
                    # stdout/stderr をキャプチャ
                    stdout_buf = io.StringIO()
                    stderr_buf = io.StringIO()
                    with contextlib.redirect_stdout(stdout_buf):
                        with contextlib.redirect_stderr(stderr_buf):
                            result = main()

            self.assertEqual(result, 0)
            self.assertTrue(out_file.exists())
            content = out_file.read_text()
            self.assertIn("window.DAILY_NEWS", content)
            # JSON 内容を検証
            import json
            js_content = content.replace("window.DAILY_NEWS = ", "").strip()
            if js_content.endswith(";"):
                js_content = js_content[:-1]
            data = json.loads(js_content)
            self.assertEqual(len(data), 2)
            self.assertIn("2026-08-01", data)
            self.assertIn("2026-08-02", data)


if __name__ == "__main__":
    unittest.main()
