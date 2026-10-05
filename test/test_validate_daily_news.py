import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = REPO_ROOT / "scripts" / "validate_daily_news.py"


def news_section(count: int, date: str = "2026-10-06") -> str:
    items = "\n\n".join(
        f"- **【技術】テストニュース{i}**（[出典](https://example.com/{i})）\n  概要です。"
        for i in range(count)
    )
    return f"# 2026年10月 AIニュースまとめ\n\n## {date}\n\n{items}\n"


class ValidateDailyNewsTest(unittest.TestCase):
    def validate(self, content: str, date: str = "2026-10-06") -> subprocess.CompletedProcess:
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            (repo / "everyday_news").mkdir()
            (repo / "everyday_news" / "202610.md").write_text(content, encoding="utf-8")
            return subprocess.run(
                ["python3", str(VALIDATOR), "--repo", str(repo), "--date", date],
                text=True,
                capture_output=True,
                check=False,
            )

    def test_accepts_five_news_items(self):
        result = self.validate(news_section(5))
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_rejects_four_news_items(self):
        result = self.validate(news_section(4))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("4件", result.stderr)
        self.assertIn("5件", result.stderr)

    def test_rejects_the_same_story_repeated_five_times(self):
        duplicate = "- **【技術】同じニュース**（[出典](https://example.com/same)）\n  概要です。"
        result = self.validate("# 2026年10月 AIニュースまとめ\n\n## 2026-10-06\n\n" + "\n\n".join([duplicate] * 5))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("重複を除くと1件", result.stderr)

    def test_counts_transitively_linked_title_url_duplicates_once(self):
        section = """# 2026年10月 AIニュースまとめ

## 2026-10-06

- **【技術】見出しA**（[出典](https://example.com/1)）
  概要です。
- **【技術】見出しB**（[出典](https://example.com/1)）
  概要です。
- **【技術】見出しB**（[出典](https://example.com/2)）
  概要です。
"""
        result = self.validate(section)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("重複を除くと1件", result.stderr)

    def test_counts_only_the_requested_date_section(self):
        content = news_section(5, "2026-10-05") + "\n" + news_section(1, "2026-10-06")
        result = self.validate(content)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("1件", result.stderr)

    def test_rejects_missing_date_section(self):
        result = self.validate(news_section(5, "2026-10-05"))
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("2026-10-06", result.stderr)

    def test_revision_checks_committed_content_not_working_tree(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            repo = Path(temp_dir)
            news_dir = repo / "everyday_news"
            news_dir.mkdir()
            (news_dir / "202610.md").write_text(news_section(1), encoding="utf-8")
            subprocess.run(["git", "init", "-q", str(repo)], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.email", "test@example.com"], check=True)
            subprocess.run(["git", "-C", str(repo), "config", "user.name", "test"], check=True)
            subprocess.run(["git", "-C", str(repo), "add", "."], check=True)
            subprocess.run(["git", "-C", str(repo), "commit", "-q", "-m", "one story"], check=True)
            (news_dir / "202610.md").write_text(news_section(5), encoding="utf-8")
            result = subprocess.run(
                ["python3", str(VALIDATOR), "--repo", str(repo), "--date", "2026-10-06", "--revision", "HEAD"],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("1件", result.stderr)


if __name__ == "__main__":
    unittest.main()
