"""generate_glossary_data.py の入力検証と出力処理のテスト。"""

import importlib.util
import stat
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "scripts" / "generate_glossary_data.py"
SPEC = importlib.util.spec_from_file_location("generate_glossary_data", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class GenerateGlossaryDataTest(unittest.TestCase):
    def test_rejects_row_with_fewer_than_three_columns(self):
        with self.assertRaises(MODULE.GlossaryParseError):
            MODULE.build_sections(
                "## 1. テスト\n"
                "| 用語 | 正式名称 / 読み | 意味 |\n"
                "|---|---|---|\n"
                "| **AI** | Artificial Intelligence |\n"
            )

    def test_allows_empty_expansion_when_no_expansion_exists(self):
        sections = MODULE.build_sections(
            "## 1. テスト\n"
            "| 用語 | 正式名称 / 読み | 意味 |\n"
            "|---|---|---|\n"
            "| **AI** |  | 説明 |\n"
        )

        self.assertEqual(sections[0]["entries"][0]["sub"], "")

    def test_rejects_empty_term_or_description(self):
        for row in ("|  | 読み | 説明 |\n", "| **AI** | 読み |  |\n"):
            with self.subTest(row=row), self.assertRaises(MODULE.GlossaryParseError):
                MODULE.build_sections(
                    "## 1. テスト\n"
                    "| 用語 | 正式名称 / 読み | 意味 |\n"
                    "|---|---|---|\n"
                    + row
                )

    def test_rejects_empty_model_name_in_model_section(self):
        with self.assertRaises(MODULE.GlossaryParseError):
            MODULE.build_sections(
                "## 9. モデル\n"
                "| 開発元 | モデル / シリーズ | 補足 |\n"
                "|---|---|---|\n"
                "| **Google** |  | 補足テキスト |\n"
            )

    def test_rejects_invalid_header(self):
        with self.assertRaises(MODULE.GlossaryParseError):
            MODULE.build_sections(
                "## 1. テスト\n"
                "| 列A | 列B | 列C |\n"
                "|---|---|---|\n"
                "| **AI** | Artificial Intelligence | 説明 |\n"
            )

    def test_builds_valid_section(self):
        sections = MODULE.build_sections(
            "## 1. テスト\n"
            "| 用語 | 正式名称 / 読み | 意味 |\n"
            "|---|---|---|\n"
            "| **AI** | Artificial Intelligence | 説明 |\n"
        )

        self.assertEqual(sections[0]["entries"][0]["term"], "<strong>AI</strong>")

    def test_atomic_write_replaces_output(self):
        with tempfile.TemporaryDirectory() as tmp:
            output = Path(tmp) / "glossary-data.js"
            output.write_text("old content", encoding="utf-8")
            output.chmod(0o644)
            MODULE.write_output(output, "new content")

            self.assertEqual(output.read_text(encoding="utf-8"), "new content")
            self.assertEqual(stat.S_IMODE(output.stat().st_mode), 0o644)
            self.assertEqual(list(Path(tmp).glob(".glossary-data.js.*")), [])

    def test_main_preserves_existing_output_when_source_is_invalid(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "glossary.md"
            output = Path(tmp) / "glossary-data.js"
            source.write_text(
                "## 1. テスト\n"
                "| 用語 | 正式名称 / 読み | 意味 |\n"
                "|---|---|---|\n"
                "| **AI** | 説明列なし |\n",
                encoding="utf-8",
            )
            output.write_text("old content", encoding="utf-8")
            old_source = MODULE.SRC_FILE
            old_output = MODULE.OUT_FILE
            try:
                MODULE.SRC_FILE = source
                MODULE.OUT_FILE = output
                self.assertEqual(MODULE.main(), 1)
            finally:
                MODULE.SRC_FILE = old_source
                MODULE.OUT_FILE = old_output

            self.assertEqual(output.read_text(encoding="utf-8"), "old content")


if __name__ == "__main__":
    unittest.main()
