# AI DAILY LOG ページ 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `everyday_news/YYYYMM.md` の日次AIニュースログを、カレンダーで日付を選ぶとカード形式で読める `history/daily.html` として公開し、毎朝の自動更新に組み込む。

**Architecture:** `scripts/generate_daily_data.py` が `everyday_news/*.md` をパースして `history/daily-data.js`（`window.DAILY_NEWS`）を全件再生成する。`history/daily.html` はビルド無しの単一静的ファイルで、そのグローバル変数だけを読んでカレンダーとカードをクライアント側で描画する。既存の `report/*.md` → `generate_reports_data.py` → `reports-data.js` → `news.html` とまったく同じ役割分担。

**Tech Stack:** 素の HTML / CSS / JavaScript（フレームワーク・ビルド無し）、Python 3 標準ライブラリのみ、`unittest`。

## Global Constraints

- 新しい外部依存を足さない。npm パッケージ・CDN スクリプトの追加は禁止。Python は標準ライブラリのみ。
- Vercel の公開ルートは `history/`。ブラウザから読ませるファイルは必ず `history/` 配下に置く。
- ユーザーに見える文字列（ページ内テキスト、エラーメッセージ、コミットメッセージ、コメント）はすべて日本語で書く。
- 設計書は `docs/superpowers/specs/2026-08-02-daily-log-page-design.md`。判断に迷ったらこれを正とする。
- `history/news.html` の7テーマ構成・カード循環ロジック、`history/reports-data.js`、`history/report-modal.js` には触れない。
- `history/daily-data.js` は生成物。手で編集しない。
- 各タスクの最後に必ずコミットする。コミットメッセージは既存の日本語形式に合わせる。

---

### Task 1: `generate_daily_data.py` — Markdown → JSON 変換

**Files:**
- Create: `scripts/generate_daily_data.py`
- Test: `tests/test_generate_daily_data.py`

**Interfaces:**
- Consumes: なし（最初のタスク）
- Produces:
  - `ParseError(Exception)` — 形式不一致を表す例外
  - `render_inline(text: str) -> str` — 本文中の `**強調**` を `<strong>` に変換
  - `parse_daily_markdown(text: str, source: str) -> dict[str, list[dict[str, str]]]` — 1ファイル分の Markdown を `{"YYYY-MM-DD": [{"title": str, "body": str, "url": str}, ...]}` に変換。形式不一致で `ParseError`
  - `main() -> int` — 全ファイルを処理して `history/daily-data.js` を書く。異常時は 1 を返し、ファイルを書き換えない
  - 出力する JS のグローバル変数名は `window.DAILY_NEWS`。Task 3・4 がこれを読む

- [ ] **Step 1: 失敗するテストを書く**

`tests/test_generate_daily_data.py` を新規作成する。

```python
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
```

- [ ] **Step 2: テストを実行して失敗を確認する**

Run: `cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news" && python3 -m unittest discover -s tests -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'generate_daily_data'`

- [ ] **Step 3: 実装を書く**

`scripts/generate_daily_data.py` を新規作成する。

```python
#!/usr/bin/env python3
"""everyday_news/*.md を history/daily-data.js に変換する。

daily.html のカレンダー＋カード表示用データ。
scripts/daily_news_prompt.txt の手順9(commit直前)で毎朝実行される想定。
形式に合わない行を見つけたら stderr に出して終了コード1で落ち、
daily-data.js は書き換えない(壊れた形式で項目を黙って取りこぼさないため)。
"""
import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SRC_DIR = REPO_ROOT / "everyday_news"
OUT_FILE = REPO_ROOT / "history" / "daily-data.js"

DATE_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
ITEM_RE = re.compile(r"^-\s+\*\*(.+?)\*\*[:：]\s*(.+)$")
SOURCE_RE = re.compile(r"[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")


class ParseError(Exception):
    """everyday_news の Markdown が想定形式に一致しないことを表す。"""


def render_inline(text: str) -> str:
    """本文中の **強調** を <strong> に変換する。他のマークアップは扱わない。"""
    return BOLD_RE.sub(r"<strong>\1</strong>", text)


def parse_daily_markdown(text: str, source: str) -> dict:
    """1ファイル分の Markdown を {日付: [項目, ...]} に変換する。

    項目は {"title": str, "body": str, "url": str}。
    想定形式に一致しない行があれば ParseError を送出する。
    """
    result: dict = {}
    current = None

    for lineno, raw in enumerate(text.split("\n"), 1):
        line = raw.strip()

        if not line:
            continue

        # ファイル先頭の「# 2026年8月 AIニュースまとめ」は読み飛ばす
        if line.startswith("# "):
            continue

        matched_date = DATE_RE.match(line)
        if matched_date:
            current = matched_date.group(1)
            result.setdefault(current, [])
            continue

        if line.startswith("- "):
            if current is None:
                raise ParseError(
                    f"{source}:{lineno}: 日付見出し(## YYYY-MM-DD)より前に項目行があります: {line}"
                )
            matched_item = ITEM_RE.match(line)
            if not matched_item:
                raise ParseError(
                    f"{source}:{lineno}: '- **見出し**: 本文' の形式ではありません: {line}"
                )
            title = matched_item.group(1).strip()
            rest = matched_item.group(2).strip()
            matched_src = SOURCE_RE.search(rest)
            if not matched_src:
                raise ParseError(
                    f"{source}:{lineno}: 末尾の（[出典](URL)）が見つかりません: {line}"
                )
            result[current].append(
                {
                    "title": render_inline(title),
                    "body": render_inline(SOURCE_RE.sub("", rest).strip()),
                    "url": matched_src.group(1),
                }
            )
            continue

        raise ParseError(f"{source}:{lineno}: 解釈できない行です: {line}")

    return result


def main() -> int:
    data: dict = {}
    errors: list = []

    for path in sorted(SRC_DIR.glob("*.md")):
        try:
            parsed = parse_daily_markdown(path.read_text(encoding="utf-8"), path.name)
        except ParseError as err:
            errors.append(str(err))
            continue
        for date, items in parsed.items():
            if date in data:
                errors.append(f"{path.name}: 日付 {date} が複数ファイルに重複しています")
                continue
            data[date] = items

    if errors:
        for err in errors:
            print(err, file=sys.stderr)
        print("エラーがあるため history/daily-data.js は更新していません。", file=sys.stderr)
        return 1

    ordered = {date: data[date] for date in sorted(data)}
    js = "window.DAILY_NEWS = " + json.dumps(ordered, ensure_ascii=False, indent=2) + ";\n"
    OUT_FILE.write_text(js, encoding="utf-8")

    item_count = sum(len(v) for v in ordered.values())
    print(f"generated {OUT_FILE} ({len(ordered)} days, {item_count} items)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: テストを実行して通ることを確認する**

Run: `cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news" && python3 -m unittest discover -s tests -v`
Expected: PASS（11 tests、failures 0）

- [ ] **Step 5: スクリプトを実行して daily-data.js を生成する**

Run: `cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news" && python3 scripts/generate_daily_data.py`
Expected: `generated .../history/daily-data.js (24 days, 141 items)` — 日次ジョブが走っていれば数字は増える。stderr は空。

- [ ] **Step 6: 異常系を手で確認する**

壊れた md を一時ファイルで作り、終了コード1で落ちて `daily-data.js` が変わらないことを確かめる。

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
BEFORE=$(shasum history/daily-data.js | cut -d' ' -f1)
printf '## 2026-01-01\n- 太字見出しのない項目です。\n' > everyday_news/_tmp_broken.md
python3 scripts/generate_daily_data.py; echo "exit=$?"
AFTER=$(shasum history/daily-data.js | cut -d' ' -f1)
rm everyday_news/_tmp_broken.md
[ "$BEFORE" = "$AFTER" ] && echo "OK: daily-data.js は変更されていない" || echo "NG: 書き換わってしまった"
```

Expected: stderr に `_tmp_broken.md:2: '- **見出し**: 本文' の形式ではありません` と `エラーがあるため history/daily-data.js は更新していません。`、`exit=1`、`OK: daily-data.js は変更されていない`

（この確認で作る `everyday_news/_tmp_broken.md` は上の手順内で `rm` する一時ファイル。それ以外のファイルは削除しない。）

- [ ] **Step 7: コミット**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add scripts/generate_daily_data.py tests/test_generate_daily_data.py history/daily-data.js
git commit -m "$(cat <<'EOF'
everyday_news を daily-data.js に変換するスクリプトを追加

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: `daily.html` の静的シェル（HTML + CSS）

**Files:**
- Create: `history/daily.html`

**Interfaces:**
- Consumes: `history/daily-data.js`（Task 1 が生成。このタスクでは `<script src>` で読み込むだけで中身は使わない）
- Produces: Task 3・4 の JS が掴む DOM の id
  - `#cal-title` — 「2026年 8月」を入れる要素
  - `#cal-prev` / `#cal-next` — 月送りボタン（`<button>`）
  - `#cal-latest` — 最新日へ戻るボタン（`<button>`）
  - `#cal-grid` — 曜日ヘッダ7セル＋日セルを `innerHTML` で流し込む 7列グリッド
  - `#day-head` — 選択日の見出しを `innerHTML` で流し込む要素
  - `#card-grid` — カードを `innerHTML` で流し込む `.news-grid`
  - `#empty-state` — データが1件も無いときに出す要素（初期状態は `hidden`）
  - CSS クラス: `.cal-cell` `.cal-cell.empty` `.cal-cell.has-news` `.cal-cell.selected` `.cal-count` `.cal-dow` `.cal-dow.sun` `.cal-dow.sat` `.news-card` `.news-card.visible` `.kicker` `.card-src` `.day-count` `.day-line`

- [ ] **Step 1: ファイルを作成する**

`history/daily.html` を新規作成する。`news.html` の配色・タイポグラフィをそのまま踏襲するが、使わない CSS（ティッカー、クイックフィルタ、レポートモーダル、テーマ別カラー、KaTeX）は入れない。KaTeX の CDN も読み込まない。

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI DAILY LOG — 日次AIニュース</title>
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/svg+xml" href="favicon.svg">
<link rel="icon" type="image/png" sizes="32x32" href="favicon-32x32.png">
<link rel="icon" type="image/png" sizes="16x16" href="favicon-16x16.png">
<link rel="apple-touch-icon" href="apple-touch-icon.png">
<link rel="manifest" href="manifest.json">
<meta name="theme-color" content="#00e5ff">
<meta name="description" content="毎朝更新されるAI業界の日次ニュースログ。カレンダーで日付を選ぶと、その日の重要ニュースをカードで読める。">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;600;800&family=Noto+Sans+JP:wght@300;400;500;700&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
<style>
:root {
  --bg: #05060f;
  --bg-2: #0a0d1f;
  --cyan: #00e5ff;
  --magenta: #ff2ee6;
  --violet: #8b5cf6;
  --green: #00ffa3;
  --amber: #ffb547;
  --coral: #ff7a5c;
  --blue: #5c9dff;
  --text: #e6ecff;
  --text-dim: #8a94b8;
  --card: rgba(20, 25, 55, 0.55);
  --border: rgba(0, 255, 163, 0.18);
}

* { margin: 0; padding: 0; box-sizing: border-box; }
html { scroll-behavior: smooth; }

body {
  background: var(--bg);
  color: var(--text);
  font-family: 'Noto Sans JP', sans-serif;
  overflow-x: hidden;
  line-height: 1.8;
}

#neural-bg { position: fixed; inset: 0; z-index: 0; opacity: 0.45; }

.grid-overlay {
  position: fixed; inset: 0; z-index: 1; pointer-events: none;
  background-image:
    linear-gradient(rgba(0, 255, 163, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0, 255, 163, 0.03) 1px, transparent 1px);
  background-size: 60px 60px;
  mask-image: radial-gradient(ellipse at 50% 0%, black 0%, transparent 75%);
  -webkit-mask-image: radial-gradient(ellipse at 50% 0%, black 0%, transparent 75%);
}

.content { position: relative; z-index: 2; }

/* ===== Nav ===== */
nav {
  position: fixed; top: 0; left: 0; right: 0; z-index: 100;
  display: flex; align-items: center; justify-content: space-between;
  padding: 14px 32px;
  background: rgba(5, 6, 15, 0.7);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-bottom: 1px solid var(--border);
}

.nav-logo {
  font-family: 'Orbitron', sans-serif; font-weight: 800; font-size: 1.05rem;
  letter-spacing: 0.18em;
  background: linear-gradient(90deg, var(--green), var(--cyan));
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
}

.nav-links { display: flex; gap: 24px; align-items: center; }

.nav-links a {
  color: var(--text-dim); text-decoration: none; font-size: 0.82rem;
  letter-spacing: 0.08em; transition: color 0.25s, text-shadow 0.25s;
}
.nav-links a:hover { color: var(--green); text-shadow: 0 0 12px rgba(0,255,163,0.7); }

.back-btn {
  font-family: 'JetBrains Mono', monospace;
  font-size: 0.75rem !important;
  color: var(--cyan) !important;
  border: 1px solid rgba(0,229,255,0.35);
  padding: 5px 14px; border-radius: 999px;
  background: rgba(0,229,255,0.06);
}
.back-btn:hover { box-shadow: 0 0 14px rgba(0,229,255,0.4); }

/* ===== Hero ===== */
.hero {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  text-align: center; padding: 118px 24px 26px;
}

.hero-tag {
  font-family: 'JetBrains Mono', monospace; font-size: 0.8rem;
  color: var(--green);
  border: 1px solid rgba(0,255,163,0.4); border-radius: 999px;
  padding: 6px 20px; margin-bottom: 22px;
  background: rgba(0,255,163,0.06);
  animation: pulse-border 3s ease-in-out infinite;
}
@keyframes pulse-border {
  0%, 100% { box-shadow: 0 0 8px rgba(0,255,163,0.25); }
  50% { box-shadow: 0 0 22px rgba(0,255,163,0.55); }
}

.hero h1 {
  font-family: 'Orbitron', sans-serif; font-weight: 800;
  font-size: clamp(1.8rem, 5.5vw, 3.6rem);
  letter-spacing: 0.1em; line-height: 1.15;
  background: linear-gradient(120deg, var(--green) 0%, var(--cyan) 55%, var(--violet) 100%);
  background-size: 200% 200%;
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
  animation: gradient-shift 6s ease infinite;
}
@keyframes gradient-shift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}

.hero h2 {
  margin-top: 14px; font-weight: 300;
  font-size: clamp(0.85rem, 2vw, 1.1rem);
  color: var(--text-dim); letter-spacing: 0.22em;
}

/* ===== Calendar ===== */
.cal-wrap { max-width: 560px; margin: 0 auto; padding: 0 24px 8px; }

.cal-head {
  display: flex; align-items: center; justify-content: space-between;
  gap: 10px; margin-bottom: 14px;
}

.cal-title {
  font-family: 'Orbitron', sans-serif; font-size: 1.02rem;
  letter-spacing: 0.12em; color: var(--text); flex: 1; text-align: center;
}

.cal-nav {
  flex: 0 0 auto;
  width: 34px; height: 34px; border-radius: 50%;
  border: 1px solid var(--border);
  background: rgba(0,255,163,0.06);
  color: var(--green); font-size: 0.85rem; line-height: 1;
  cursor: pointer; transition: box-shadow 0.25s;
}
.cal-nav:hover:not(:disabled) { box-shadow: 0 0 14px rgba(0,255,163,0.4); }
.cal-nav:disabled { opacity: 0.22; cursor: default; }

.cal-latest {
  flex: 0 0 auto;
  font-family: 'JetBrains Mono', monospace; font-size: 0.68rem;
  color: var(--cyan);
  border: 1px solid rgba(0,229,255,0.35);
  background: rgba(0,229,255,0.06);
  border-radius: 999px; padding: 5px 13px; cursor: pointer;
  transition: box-shadow 0.25s;
}
.cal-latest:hover { box-shadow: 0 0 14px rgba(0,229,255,0.4); }

.cal-grid { display: grid; grid-template-columns: repeat(7, 1fr); gap: 6px; }

.cal-dow {
  text-align: center; padding-bottom: 4px;
  font-family: 'JetBrains Mono', monospace; font-size: 0.66rem;
  color: var(--text-dim); letter-spacing: 0.1em;
}
.cal-dow.sun { color: var(--coral); }
.cal-dow.sat { color: var(--blue); }

.cal-cell {
  aspect-ratio: 1 / 1;
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1px;
  border-radius: 9px;
  border: 1px solid rgba(255,255,255,0.07);
  background: rgba(20,25,55,0.4);
  font-family: 'JetBrains Mono', monospace; font-size: 0.85rem;
  color: var(--text-dim);
}
.cal-cell.empty { border-color: transparent; background: transparent; }

.cal-cell.has-news {
  color: var(--green);
  border-color: rgba(0,255,163,0.45);
  background: rgba(0,255,163,0.07);
  text-shadow: 0 0 10px rgba(0,255,163,0.55);
  cursor: pointer;
  transition: box-shadow 0.25s, transform 0.25s;
}
.cal-cell.has-news:hover { box-shadow: 0 0 16px rgba(0,255,163,0.35); transform: translateY(-2px); }
.cal-cell.has-news:focus-visible { outline: 2px solid var(--green); outline-offset: 2px; }

.cal-cell.selected {
  background: var(--green); color: var(--bg);
  border-color: var(--green); text-shadow: none;
  box-shadow: 0 0 22px rgba(0,255,163,0.55);
}

.cal-count { font-size: 0.56rem; letter-spacing: 0.04em; opacity: 0.85; }
.cal-cell.selected .cal-count { opacity: 0.7; }

/* ===== Selected day ===== */
.day-head {
  max-width: 1100px; margin: 0 auto;
  padding: 34px 24px 0;
  display: flex; align-items: baseline; gap: 14px; flex-wrap: wrap;
}
.day-head h2 {
  font-family: 'Orbitron', 'Noto Sans JP', sans-serif;
  font-size: clamp(1.05rem, 3vw, 1.45rem); font-weight: 600;
  letter-spacing: 0.05em; color: var(--green);
}
.day-head .day-count {
  font-family: 'JetBrains Mono', monospace; font-size: 0.72rem; color: var(--text-dim);
}
.day-head .day-line {
  flex: 1; height: 1px; min-width: 40px;
  background: linear-gradient(90deg, rgba(0,255,163,0.6), transparent);
}

.cards-wrap { max-width: 1100px; margin: 0 auto; padding: 26px 24px 10px; }

.news-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(310px, 1fr)); gap: 18px; }

.news-card {
  background: var(--card);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 12px; padding: 22px 24px;
  backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
  opacity: 0; transform: translateY(24px);
  display: flex; flex-direction: column;
  align-items: flex-start;
}
.news-card.visible {
  opacity: 1; transform: translateY(0);
  transition: opacity 0.55s, transform 0.55s, box-shadow 0.3s;
}
.news-card:hover { box-shadow: 0 8px 36px rgba(0,255,163,0.12); }

.news-card .kicker {
  font-family: 'JetBrains Mono', monospace; font-size: 0.64rem;
  letter-spacing: 0.14em; margin-bottom: 6px; color: var(--cyan);
}
.news-card h3 { font-size: 1rem; font-weight: 700; margin-bottom: 8px; line-height: 1.55; }
.news-card p { font-size: 0.83rem; color: var(--text-dim); line-height: 1.75; flex: 1; }
.news-card strong { color: var(--text); }

.card-src {
  margin-top: 14px; padding-top: 10px; width: 100%;
  border-top: 1px dashed rgba(255,255,255,0.12);
  font-family: 'JetBrains Mono', monospace; font-size: 0.68rem;
  color: var(--green); text-decoration: none;
  transition: text-shadow 0.25s;
}
.card-src:hover { text-shadow: 0 0 10px rgba(0,255,163,0.7); }

#empty-state {
  max-width: 1100px; margin: 0 auto; padding: 60px 24px;
  text-align: center; color: var(--coral);
  font-family: 'JetBrains Mono', monospace; font-size: 0.85rem;
}
#empty-state[hidden] { display: none; }

/* ===== CTA / footer ===== */
.cta-back { text-align: center; padding: 70px 24px 100px; display: flex; gap: 18px; justify-content: center; flex-wrap: wrap; }
.cta-back a {
  display: inline-block;
  font-family: 'JetBrains Mono', monospace; font-size: 0.85rem;
  text-decoration: none; border-radius: 999px; padding: 12px 34px;
  transition: box-shadow 0.3s, transform 0.3s;
}
.cta-back a.to-news {
  color: var(--green);
  border: 1px solid rgba(0,255,163,0.4);
  background: rgba(0,255,163,0.05);
}
.cta-back a.to-news:hover { box-shadow: 0 0 26px rgba(0,255,163,0.4); transform: translateY(-2px); }
.cta-back a.to-index {
  color: var(--cyan);
  border: 1px solid rgba(0,229,255,0.4);
  background: rgba(0,229,255,0.05);
}
.cta-back a.to-index:hover { box-shadow: 0 0 26px rgba(0,229,255,0.4); transform: translateY(-2px); }

footer {
  border-top: 1px solid var(--border); padding: 34px 24px; text-align: center;
  color: var(--text-dim); font-size: 0.75rem; letter-spacing: 0.1em;
  background: rgba(5, 6, 15, 0.8);
}
footer .logo {
  font-family: 'Orbitron', sans-serif; font-weight: 800; letter-spacing: 0.2em;
  background: linear-gradient(90deg, var(--green), var(--cyan));
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 8px; font-size: 0.95rem;
}

#progress {
  position: fixed; top: 0; left: 0; height: 3px; width: 0%;
  background: linear-gradient(90deg, var(--green), var(--cyan), var(--violet));
  z-index: 200; box-shadow: 0 0 12px rgba(0,255,163,0.7);
}

@media (max-width: 768px) {
  nav { padding: 12px 16px; }
  .nav-links a:not(.back-btn) { display: none; }
  .hero { padding-top: 100px; }
  .cal-wrap { padding: 0 12px 8px; }
  .cal-grid { gap: 4px; }
  .cal-cell { border-radius: 7px; font-size: 0.76rem; }
  .cal-count { font-size: 0.5rem; }
  .cal-title { font-size: 0.86rem; letter-spacing: 0.08em; }
  .cal-nav { width: 30px; height: 30px; }
  .cal-latest { padding: 4px 10px; font-size: 0.62rem; }
  .news-grid { grid-template-columns: 1fr; }
}
</style>
</head>
<body>

<div id="progress"></div>
<canvas id="neural-bg"></canvas>
<div class="grid-overlay"></div>

<nav>
  <div class="nav-logo">AI DAILY LOG</div>
  <div class="nav-links">
    <a href="news.html">最新ニュース</a>
    <a href="archive.html">過去ログ</a>
    <a class="back-btn" href="index.html">← AI HISTORY</a>
  </div>
</nav>

<div class="content">

  <header class="hero">
    <div class="hero-tag">DAILY LOG — 毎朝更新</div>
    <h1>AI DAILY LOG</h1>
    <h2>日付を選んでその日のニュースを読む</h2>
  </header>

  <div class="cal-wrap">
    <div class="cal-head">
      <button type="button" id="cal-prev" class="cal-nav" aria-label="前の月">◀</button>
      <span class="cal-title" id="cal-title"></span>
      <button type="button" id="cal-next" class="cal-nav" aria-label="次の月">▶</button>
      <button type="button" id="cal-latest" class="cal-latest">最新</button>
    </div>
    <div class="cal-grid" id="cal-grid"></div>
  </div>

  <div class="day-head" id="day-head"></div>

  <div class="cards-wrap">
    <div class="news-grid" id="card-grid"></div>
  </div>

  <div id="empty-state" hidden>日次ニュースのデータがまだありません。</div>

  <div class="cta-back">
    <a class="to-news" href="news.html">テーマ別の最新トレンドを見る →</a>
    <a class="to-index" href="index.html">← AI HISTORY 全体年表</a>
  </div>

</div>

<footer>
  <div class="logo">AI DAILY LOG</div>
  <div>SOURCE: ai_news/everyday_news · 毎朝自動更新</div>
</footer>

<script src="daily-data.js"></script>
<script>
/* ===== Neural network background (green tint) ===== */
const canvas = document.getElementById('neural-bg');
const ctx = canvas.getContext('2d');
let W, H;
const nodes = [];

function resize() {
  W = canvas.width = window.innerWidth;
  H = canvas.height = window.innerHeight;
}
resize();
window.addEventListener('resize', resize);

const NODE_COUNT = Math.min(90, Math.floor(window.innerWidth / 16));
const COLORS = ['0,255,163', '0,229,255', '139,92,246', '255,181,71'];

for (let i = 0; i < NODE_COUNT; i++) {
  nodes.push({
    x: Math.random() * window.innerWidth,
    y: Math.random() * window.innerHeight,
    vx: (Math.random() - 0.5) * 0.4,
    vy: (Math.random() - 0.5) * 0.4,
    r: Math.random() * 1.8 + 0.8,
    c: COLORS[Math.floor(Math.random() * COLORS.length)]
  });
}

const mouse = { x: -9999, y: -9999 };
window.addEventListener('mousemove', e => { mouse.x = e.clientX; mouse.y = e.clientY; });

function draw() {
  ctx.clearRect(0, 0, W, H);
  const LINK = 140;
  for (let i = 0; i < nodes.length; i++) {
    const a = nodes[i];
    a.x += a.vx; a.y += a.vy;
    if (a.x < 0 || a.x > W) a.vx *= -1;
    if (a.y < 0 || a.y > H) a.vy *= -1;
    for (let j = i + 1; j < nodes.length; j++) {
      const b = nodes[j];
      const dx = a.x - b.x, dy = a.y - b.y;
      const d = Math.sqrt(dx * dx + dy * dy);
      if (d < LINK) {
        ctx.beginPath();
        ctx.strokeStyle = `rgba(${a.c},${(1 - d / LINK) * 0.2})`;
        ctx.lineWidth = 0.6;
        ctx.moveTo(a.x, a.y);
        ctx.lineTo(b.x, b.y);
        ctx.stroke();
      }
    }
    const mdx = a.x - mouse.x, mdy = a.y - mouse.y;
    const md = Math.sqrt(mdx * mdx + mdy * mdy);
    if (md < 180) {
      ctx.beginPath();
      ctx.strokeStyle = `rgba(0,255,163,${(1 - md / 180) * 0.4})`;
      ctx.lineWidth = 0.8;
      ctx.moveTo(a.x, a.y);
      ctx.lineTo(mouse.x, mouse.y);
      ctx.stroke();
    }
    ctx.beginPath();
    ctx.fillStyle = `rgba(${a.c},0.85)`;
    ctx.arc(a.x, a.y, a.r, 0, Math.PI * 2);
    ctx.fill();
  }
  requestAnimationFrame(draw);
}
draw();

/* ===== Progress bar ===== */
window.addEventListener('scroll', () => {
  const h = document.documentElement;
  const p = h.scrollTop / (h.scrollHeight - h.clientHeight) * 100;
  document.getElementById('progress').style.width = p + '%';
}, { passive: true });
</script>

</body>
</html>
```

- [ ] **Step 2: ローカルサーバで表示を確認する**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news/history" && python3 -m http.server 8765
```

をバックグラウンドで起動し、Chrome（claude-in-chrome）で `http://localhost:8765/daily.html` を開く。

Expected:
- ナビ・ヒーロー・ニューラルネット背景・フッターが `news.html` と同じ見た目で表示される
- カレンダーの月見出し・グリッド・カードエリアはまだ空（JS 未実装のため）
- コンソールエラーが無い。`read_console_messages` で確認する

- [ ] **Step 3: DOM の骨組みを検証する**

Chrome の `javascript_tool` で以下を評価する。

```js
['cal-title','cal-prev','cal-next','cal-latest','cal-grid','day-head','card-grid','empty-state']
  .map(id => id + '=' + !!document.getElementById(id)).join(', ')
  + ' | DAILY_NEWS days=' + Object.keys(window.DAILY_NEWS || {}).length
```

Expected: すべて `=true`、`DAILY_NEWS days=24` 以上

- [ ] **Step 4: コミット**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add history/daily.html
git commit -m "$(cat <<'EOF'
AI DAILY LOGページの静的シェルを追加

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: カレンダーの描画と月送り

**Files:**
- Modify: `history/daily.html`（末尾の `<script>` ブロック内、`/* ===== Progress bar ===== */` の後ろに追記）

**Interfaces:**
- Consumes: `window.DAILY_NEWS`（Task 1）、Task 2 が定義した DOM id と CSS クラス
- Produces: Task 4 が使う変数・関数
  - `DATA` — `window.DAILY_NEWS`
  - `DATES: string[]` — 昇順の日付キー配列
  - `LATEST: string | null` — 最新日
  - `DOW: string[]` — `['日','月','火','水','木','金','土']`
  - `selected: string | null` — 選択中の日付（`let`）
  - `viewMonth: string | null` — 表示中の月 `"YYYY-MM"`（`let`）
  - `ym(dateStr: string) -> string` — 日付から `"YYYY-MM"` を取り出す
  - `renderCalendar() -> void` — `#cal-title` と `#cal-grid` を再描画し、月送りボタンの `disabled` を更新する
  - DOM 参照の定数: `calTitle` `calGrid` `prevBtn` `nextBtn` `latestBtn` `emptyState`（Task 4 は `calGrid` `latestBtn` `emptyState` を使う）

- [ ] **Step 1: カレンダー描画を実装する**

`history/daily.html` の `<script>` ブロック末尾（プログレスバーの後）に追記する。

```js
/* ===== 日次ログデータ ===== */
const DATA = window.DAILY_NEWS || {};
const DATES = Object.keys(DATA).sort();
const LATEST = DATES.length ? DATES[DATES.length - 1] : null;
const DOW = ['日', '月', '火', '水', '木', '金', '土'];

const calTitle = document.getElementById('cal-title');
const calGrid = document.getElementById('cal-grid');
const prevBtn = document.getElementById('cal-prev');
const nextBtn = document.getElementById('cal-next');
const latestBtn = document.getElementById('cal-latest');
const emptyState = document.getElementById('empty-state');

function ym(dateStr) { return dateStr.slice(0, 7); }

const MONTHS = [...new Set(DATES.map(ym))].sort();
const MIN_MONTH = MONTHS[0] || null;
const MAX_MONTH = MONTHS.length ? MONTHS[MONTHS.length - 1] : null;

let selected = null;
let viewMonth = LATEST ? ym(LATEST) : null;

/* "YYYY-MM" を delta か月ずらす。年またぎは Date に任せる。 */
function shiftMonth(month, delta) {
  const [y, m] = month.split('-').map(Number);
  const d = new Date(Date.UTC(y, m - 1 + delta, 1));
  return d.getUTCFullYear() + '-' + String(d.getUTCMonth() + 1).padStart(2, '0');
}

function renderCalendar() {
  if (!viewMonth) return;
  const [y, m] = viewMonth.split('-').map(Number);
  calTitle.textContent = y + '年 ' + m + '月';
  prevBtn.disabled = viewMonth <= MIN_MONTH;
  nextBtn.disabled = viewMonth >= MAX_MONTH;

  const lead = new Date(Date.UTC(y, m - 1, 1)).getUTCDay();
  const dayCount = new Date(Date.UTC(y, m, 0)).getUTCDate();

  const cells = DOW.map((name, i) => {
    const tone = i === 0 ? ' sun' : (i === 6 ? ' sat' : '');
    return '<div class="cal-dow' + tone + '">' + name + '</div>';
  });

  for (let i = 0; i < lead; i++) cells.push('<div class="cal-cell empty"></div>');

  for (let d = 1; d <= dayCount; d++) {
    const key = viewMonth + '-' + String(d).padStart(2, '0');
    const items = DATA[key];
    if (!items) {
      cells.push('<div class="cal-cell">' + d + '</div>');
      continue;
    }
    const sel = key === selected ? ' selected' : '';
    cells.push(
      '<button type="button" class="cal-cell has-news' + sel + '"'
      + ' data-date="' + key + '" aria-label="' + key + ' ' + items.length + '件">'
      + d + '<span class="cal-count">' + items.length + '</span></button>'
    );
  }

  calGrid.innerHTML = cells.join('');
}

prevBtn.addEventListener('click', () => { viewMonth = shiftMonth(viewMonth, -1); renderCalendar(); });
nextBtn.addEventListener('click', () => { viewMonth = shiftMonth(viewMonth, 1); renderCalendar(); });

if (!DATES.length) {
  emptyState.hidden = false;
  document.querySelector('.cal-wrap').hidden = true;
} else {
  renderCalendar();
}
```

- [ ] **Step 2: ブラウザでカレンダーの描画を検証する**

ローカルサーバ（`http://localhost:8765/daily.html`）を再読み込みし、`javascript_tool` で評価する。

```js
JSON.stringify({
  title: document.getElementById('cal-title').textContent,
  dowCount: document.querySelectorAll('.cal-dow').length,
  hasNews: document.querySelectorAll('.cal-cell.has-news').length,
  lead: document.querySelectorAll('.cal-cell.empty').length,
  nextDisabled: document.getElementById('cal-next').disabled,
  prevDisabled: document.getElementById('cal-prev').disabled,
  firstNewsDate: (document.querySelector('.cal-cell.has-news') || {}).dataset?.date
})
```

Expected: `title` が最新日の月（例 `"2026年 8月"`）、`dowCount` が 7、`hasNews` がその月のニュース日数（2026年8月なら 1 以上）、`nextDisabled` が `true`（最新月なので次へ進めない）、`prevDisabled` が `false`。

- [ ] **Step 3: 月送りと端の抑止を検証する**

`javascript_tool` で以下を評価する。

```js
const prev = document.getElementById('cal-prev');
const next = document.getElementById('cal-next');
const seen = [];
for (let i = 0; i < 6 && !prev.disabled; i++) { prev.click(); seen.push(document.getElementById('cal-title').textContent); }
const atMin = { title: document.getElementById('cal-title').textContent, prevDisabled: prev.disabled };
while (!next.disabled) next.click();
JSON.stringify({ seen, atMin, atMax: document.getElementById('cal-title').textContent });
```

Expected: `seen` に 7月が含まれ、`atMin.prevDisabled` が `true`（最古月で止まる）、`atMax` が最新月。それ以上さかのぼれない・進めないこと。

- [ ] **Step 4: コンソールエラーが無いことを確認する**

`read_console_messages` で確認する。
Expected: エラー 0 件

- [ ] **Step 5: コミット**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add history/daily.html
git commit -m "$(cat <<'EOF'
AI DAILY LOGにカレンダー描画と月送りを実装

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: 日付選択・カード描画・ハッシュ同期・キーボード操作

**Files:**
- Modify: `history/daily.html`（Task 3 で追記した JS の末尾。ただし末尾の `if (!DATES.length) { ... }` 初期化ブロックはこのタスクの初期化に置き換える）

**Interfaces:**
- Consumes: Task 3 の `DATA` `DATES` `LATEST` `DOW` `selected` `viewMonth` `ym()` `renderCalendar()`、Task 2 の `#day-head` `#card-grid`
- Produces: ページとして完成。外部へ公開する関数は無い

- [ ] **Step 1: カード描画と選択処理を実装する**

Task 3 で追記した JS の末尾にある

```js
if (!DATES.length) {
  emptyState.hidden = false;
  document.querySelector('.cal-wrap').hidden = true;
} else {
  renderCalendar();
}
```

を、以下のブロックで**置き換える**。

```js
const dayHead = document.getElementById('day-head');
const cardGrid = document.getElementById('card-grid');

/* 出典URLのホスト名をキッカー表示用に整える。 */
function hostOf(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, '').toUpperCase();
  } catch (e) {
    return 'SOURCE';
  }
}

function renderDay() {
  const items = DATA[selected] || [];
  const [y, m, d] = selected.split('-').map(Number);
  const dow = DOW[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];

  dayHead.innerHTML =
    '<h2>' + selected + '（' + dow + '）</h2>'
    + '<span class="day-count">' + items.length + '件</span>'
    + '<span class="day-line"></span>';

  cardGrid.innerHTML = items.map(item =>
    '<article class="news-card">'
    + '<div class="kicker">' + hostOf(item.url) + '</div>'
    + '<h3>' + item.title + '</h3>'
    + '<p>' + item.body + '</p>'
    + '<a class="card-src" href="' + item.url + '" target="_blank" rel="noopener">出典を読む →</a>'
    + '</article>'
  ).join('');

  // 再描画のたびにフェードインさせる
  requestAnimationFrame(() => {
    cardGrid.querySelectorAll('.news-card').forEach(c => c.classList.add('visible'));
  });
}

function select(date, opts) {
  if (!DATA[date]) return;
  selected = date;
  viewMonth = ym(date);
  renderCalendar();
  renderDay();
  history.replaceState(null, '', '#' + date);
  if (opts && opts.scroll) {
    dayHead.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

calGrid.addEventListener('click', e => {
  const cell = e.target.closest('.cal-cell.has-news');
  if (cell) select(cell.dataset.date, { scroll: true });
});

latestBtn.addEventListener('click', () => select(LATEST, { scroll: true }));

/* ← → でニュースのある前後の日へジャンプする */
document.addEventListener('keydown', e => {
  if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return;
  const tag = document.activeElement ? document.activeElement.tagName : '';
  if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
  const i = DATES.indexOf(selected);
  const next = e.key === 'ArrowLeft' ? DATES[i - 1] : DATES[i + 1];
  if (next) { e.preventDefault(); select(next); }
});

window.addEventListener('hashchange', () => {
  const h = location.hash.slice(1);
  if (DATA[h] && h !== selected) select(h);
});

/* ===== 初期化 ===== */
if (!DATES.length) {
  emptyState.hidden = false;
  document.querySelector('.cal-wrap').hidden = true;
} else {
  const fromHash = location.hash.slice(1);
  select(DATA[fromHash] ? fromHash : LATEST);
}
```

- [ ] **Step 2: 初期表示とカード内容を検証する**

`http://localhost:8765/daily.html` を再読み込みし、`javascript_tool` で評価する。

```js
const cards = document.querySelectorAll('#card-grid .news-card');
const first = cards[0];
JSON.stringify({
  hash: location.hash,
  head: document.querySelector('#day-head h2').textContent,
  count: document.querySelector('#day-head .day-count').textContent,
  cards: cards.length,
  selectedCells: document.querySelectorAll('.cal-cell.selected').length,
  kicker: first.querySelector('.kicker').textContent,
  title: first.querySelector('h3').textContent.slice(0, 24),
  srcHref: first.querySelector('.card-src').getAttribute('href').slice(0, 32),
  srcTarget: first.querySelector('.card-src').getAttribute('target')
})
```

Expected: `hash` が `#<最新日>`、`head` が `2026-08-01（土）` のような表記、`cards` が `#day-head .day-count` の件数と一致、`selectedCells` が 1、`kicker` が `CNBC.COM` のようなドメイン、`srcHref` が `https://` で始まる、`srcTarget` が `_blank`。

- [ ] **Step 3: 日付クリックでカードが差し替わることを検証する**

`javascript_tool` で評価する。

```js
const before = document.querySelector('#day-head h2').textContent;
document.getElementById('cal-prev').click();          // 前の月へ
const cell = document.querySelector('.cal-cell.has-news');
cell.click();                                          // その月の最初のニュース日
JSON.stringify({
  before,
  after: document.querySelector('#day-head h2').textContent,
  clicked: cell.dataset.date,
  hash: location.hash,
  cards: document.querySelectorAll('#card-grid .news-card').length,
  selected: (document.querySelector('.cal-cell.selected') || {}).dataset?.date
})
```

Expected: `after` が `before` と異なり `clicked` の日付を含む、`hash` が `#` + `clicked`、`selected` が `clicked` と一致、`cards` が 1 以上。

- [ ] **Step 4: ハッシュ直リンクを検証する**

`http://localhost:8765/daily.html#2026-07-19` を開き直し、`javascript_tool` で評価する。

```js
JSON.stringify({
  head: document.querySelector('#day-head h2').textContent,
  month: document.getElementById('cal-title').textContent,
  cards: document.querySelectorAll('#card-grid .news-card').length
})
```

Expected: `head` に `2026-07-19` が含まれ、`month` が `2026年 7月`、`cards` が 1 以上。

続けて `http://localhost:8765/daily.html#9999-01-01`（存在しない日）を開き、同じ評価をする。
Expected: エラーにならず、`head` に最新日が入っている（無効なハッシュは無視される）。

- [ ] **Step 5: キーボード操作を検証する**

最新日を開いた状態で `javascript_tool` で評価する。

```js
const start = document.querySelector('#day-head h2').textContent;
document.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowLeft', bubbles: true }));
const afterLeft = document.querySelector('#day-head h2').textContent;
document.dispatchEvent(new KeyboardEvent('keydown', { key: 'ArrowRight', bubbles: true }));
JSON.stringify({ start, afterLeft, afterRight: document.querySelector('#day-head h2').textContent });
```

Expected: `afterLeft` が `start` の1つ前のニュース日、`afterRight` が `start` に戻る。

- [ ] **Step 6: スマホ幅を確認する**

`resize_window` でビューポートを 390×844 にし、`http://localhost:8765/daily.html` を表示してスクリーンショットを撮る。

Expected:
- カレンダーが7列を保ち、横スクロールが出ない
- カードが1列で読める
- 日付の数字と件数バッジが潰れていない

`javascript_tool` で横あふれが無いことも数値で確認する。

```js
JSON.stringify({
  scrollW: document.documentElement.scrollWidth,
  clientW: document.documentElement.clientWidth,
  calCols: getComputedStyle(document.getElementById('cal-grid')).gridTemplateColumns.split(' ').length
})
```

Expected: `scrollW <= clientW`、`calCols` が 7。

- [ ] **Step 7: コンソールエラーが無いことを確認し、検証用スクショを削除する**

`read_console_messages` で確認する。Expected: エラー 0 件。

Step 6 で撮ったスクリーンショットファイルを削除する（グローバル CLAUDE.md のスクリーンショット証跡管理方針。確認用の一時ファイルなので確認不要で削除してよい）。

- [ ] **Step 8: コミット**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add history/daily.html
git commit -m "$(cat <<'EOF'
AI DAILY LOGに日付選択とカード表示を実装

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 既存3ページからの導線

**Files:**
- Modify: `history/index.html`（nav 内、`news.html` へのリンクの直後）
- Modify: `history/news.html`（nav 内 `archive.html` リンクの前）
- Modify: `history/archive.html`（nav 内）

設計書の成果物表どおり、変更は**ナビへのリンク追加のみ**。`.cta-back` などページ下部の導線には手を入れない。

**Interfaces:**
- Consumes: Task 2 が作った `history/daily.html`
- Produces: なし

- [ ] **Step 1: `index.html` のナビにリンクを追加する**

`history/index.html:577` の「最新ニュース ▶」リンクの**直後**に以下を挿入する。既存の `nav-cta` と同じインラインスタイル方式に合わせ、色は amber（`--amber`）を使う。

```html
    <a href="daily.html" class="nav-cta" style="color: var(--amber); border: 1px solid rgba(255,181,71,0.35); border-radius: 999px; padding: 4px 14px; background: rgba(255,181,71,0.06);">デイリー ▶</a>
```

- [ ] **Step 2: `news.html` のナビにリンクを追加する**

`history/news.html:459` の `<a href="archive.html">過去ログ</a>` の**直前**に以下を挿入する。

```html
    <a href="daily.html">デイリー</a>
```

- [ ] **Step 3: `archive.html` のナビにリンクを追加する**

`history/archive.html:274` の `<a class="back-btn" href="news.html">← NEWS FEED</a>` の**直前**に以下を挿入する。

```html
    <a href="daily.html">デイリー</a>
```

- [ ] **Step 4: 4ページ間の導線をブラウザで検証する**

ローカルサーバで `javascript_tool` を使い、各ページに `daily.html` へのリンクがあることを確認する。`http://localhost:8765/index.html`、`http://localhost:8765/news.html`、`http://localhost:8765/archive.html` を順に開き、それぞれで以下を評価する。

```js
JSON.stringify({
  page: location.pathname,
  links: [...document.querySelectorAll('a[href="daily.html"]')].map(a => a.textContent.trim())
})
```

Expected: `index.html` は `["デイリー ▶"]`、`news.html` は `["デイリー"]`、`archive.html` は `["デイリー"]`。

さらに `http://localhost:8765/daily.html` を開き、逆方向の導線を確認する。

```js
JSON.stringify([...document.querySelectorAll('a[href$=".html"]')].map(a => a.getAttribute('href')))
```

Expected: `news.html` `archive.html` `index.html` がすべて含まれる。

- [ ] **Step 5: コミット**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add history/index.html history/news.html history/archive.html
git commit -m "$(cat <<'EOF'
既存3ページのナビからAI DAILY LOGへの導線を追加

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: 毎朝の自動更新への組み込みと本番反映

**Files:**
- Modify: `scripts/daily_news_prompt.txt`（手順9）
- Modify: `.claude/skills/sync-news-html/SKILL.md`（前提の記述に daily.html を1行追記）

**Interfaces:**
- Consumes: Task 1 の `scripts/generate_daily_data.py`
- Produces: なし（最終タスク）

- [ ] **Step 1: `daily_news_prompt.txt` の手順9を書き換える**

現行の手順9は次の1文になっている。

```
9. 手順8まで完了したら、everyday_news配下の変更（`<YYYYMM>.md` のみ。line_message.txtはgitignore対象なので含めない）を `<YYYY-MM-DD> のAIニュースを追加` のようなメッセージでコミットし、このリポジトリの `main` ブランチにpushする。
```

これを以下に置き換える。

```
9. 手順8まで完了したら、サイト用データを再生成してからコミット・pushする。
   - まず `python3 scripts/generate_daily_data.py` をBashで実行する。これは `everyday_news/*.md` を読んで `history/daily-data.js`（AI DAILY LOGページのカレンダー＋カード表示用データ）を全件再生成するスクリプト。
   - スクリプトが異常終了した場合（終了コードが0以外）は、`everyday_news/<YYYYMM>.md` に書いた内容が想定形式（`- **見出し**: 本文（[出典](URL)）。`）から外れている。コミット・pushは行わず、stderrに出たファイル名・行番号の該当行を手順5の形式に直してから、もう一度このスクリプトを実行する。直しても通らない場合は、コミットせずに手順10へ進み、SUMMARYにその旨を書く。
   - スクリプトが正常終了したら、`everyday_news/<YYYYMM>.md` と `history/daily-data.js` の2ファイルを `git add` する（line_message.txtはgitignore対象なので含めない）。`<YYYY-MM-DD> のAIニュースを追加` のようなメッセージでコミットし、このリポジトリの `main` ブランチにpushする。
```

- [ ] **Step 2: 手順9をシミュレートして動作を確認する**

実際のコマンド列をそのまま実行し、成功パスが通ることを確認する。

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
python3 scripts/generate_daily_data.py && echo "exit=0 なので git add に進める"
git status --short
```

Expected: `generated ... (N days, M items)` と `exit=0 なので git add に進める` が出る。`git status --short` に `history/daily-data.js` の差分が出ないこと（Task 1 で生成済みかつ md が変わっていないため冪等）。ただし作業中に日次ジョブが走って `everyday_news/*.md` に新しい日付が追記されていれば差分が出るのが正常。その場合は Step 5 のコミットに `history/daily-data.js` を含める。

- [ ] **Step 3: `sync-news-html` スキルの前提に1行追記する**

`.claude/skills/sync-news-html/SKILL.md` の「## 前提」セクション末尾に、daily.html が別系統であることを明記する（このスキルの実行者が daily.html を触らなくてよいと分かるようにするため）。

```markdown
- `history/daily.html`(AI DAILY LOG)は `everyday_news/*.md` を出典とする別系統のページで、`scripts/generate_daily_data.py` が生成する `history/daily-data.js` だけを読む。このスキルの対象外なので触らない。
```

- [ ] **Step 4: 全テストを再実行する**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
python3 -m unittest discover -s tests -v
```

Expected: PASS（failures 0, errors 0）

- [ ] **Step 5: コミットして push、本番を確認する**

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
git add scripts/daily_news_prompt.txt .claude/skills/sync-news-html/SKILL.md
git commit -m "$(cat <<'EOF'
日次ニュース自動更新にdaily-data.jsの再生成を組み込む

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
EOF
)"
git push
```

push 後、Vercel のデプロイ完了を待って https://ai-news-sandy-seven.vercel.app/daily.html を Chrome で開く。

Expected:
- 最新日のカレンダーとカードが表示される
- 7月へ月送りして任意の日を選べる
- 既存の https://ai-news-sandy-seven.vercel.app/news.html のナビから「デイリー」で遷移できる
- コンソールエラーが無い

- [ ] **Step 6: ローカルサーバを止め、検証用スクショを削除する**

Task 2 で起動した `python3 -m http.server 8765` を停止する。本番確認で撮ったスクリーンショットがあれば削除する。

---

## 実装後の確認事項（ユーザー向け）

- 翌朝 `daily_news.sh` が初めて改修後のプロンプトで走る。実行後に `git log` で `history/daily-data.js` がコミットに含まれているかを一度確認すると安全。
- 万一プロンプト改修が原因で日次ジョブが落ちた場合、`logs/daily_news.err.log` にエラーが残る。
