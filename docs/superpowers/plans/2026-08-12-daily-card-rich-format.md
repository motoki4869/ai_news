# AI DAILY LOG カードリッチフォーマット化 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `history/daily.html` のニュースカードを、見出し＋1段落の要約から、見出し（【カテゴリ】タグ付き）＋導入文＋角度別の箇条書き解説という構成に拡張し、より読みやすくする。

**Architecture:** `everyday_news/*.md` に見出し行・導入文行・`・**ラベル**: 説明` の箇条書き行という3行種からなる新フォーマットを追加する。`scripts/generate_daily_data.py` は新形式・既存の旧形式（1行完結）の両方をパースし、`{title, intro, points, url}` という統一データ形式で `history/daily-data.js` を生成する（旧形式は `points: []` になる）。`history/daily.html` はこの統一形式だけを見て描画するため、新旧のデータを分岐なく1本のロジックで表示できる。

**Tech Stack:** 素の HTML / CSS / JavaScript（フレームワーク・ビルド無し）、Python 3 標準ライブラリのみ、`unittest`。

## Global Constraints

- 新しい外部依存を足さない。npm パッケージ・CDN スクリプトの追加は禁止。Python は標準ライブラリのみ。
- Vercel の公開ルートは `history/`。ブラウザから読ませるファイルは必ず `history/` 配下に置く。
- ユーザーに見える文字列（ページ内テキスト、エラーメッセージ、コミットメッセージ、コメント）はすべて日本語で書く。
- 設計書は `docs/superpowers/specs/2026-08-12-daily-card-rich-format-design.md`。判断に迷ったらこれを正とする。
- 既存の `everyday_news/*.md` に書き込み済みの過去記事（旧形式）は書き換えない。
- `everyday_news/line_message.txt` および `scripts/daily_news_prompt.txt` の手順8（LINE通知文フォーマット）は変更しない。
- `history/news.html` / `history/archive.html` / `history/index.html` / `history/generative.html`、`history/reports-data.js`、`history/report-modal.js` には触れない。
- `history/daily-data.js` は生成物。手で編集しない（`scripts/generate_daily_data.py` の実行結果のみが正）。
- 各タスクの最後に必ずコミットする。コミットメッセージは既存の日本語形式に合わせる。

---

### Task 1: `generate_daily_data.py` — 新形式パース＋統一データ形式

**Files:**
- Modify: `scripts/generate_daily_data.py`
- Modify: `tests/test_generate_daily_data.py`

**Interfaces:**
- Consumes: なし（最初のタスク）
- Produces:
  - `parse_daily_markdown(text: str, source: str) -> dict[str, list[dict]]` — 戻り値の各項目は統一形式 `{"title": str, "intro": str, "points": list[{"label": str, "text": str}], "url": str}`（従来の `"body"` キーは廃止し `"intro"` に置き換え、`"points"` を新規追加。旧形式の項目は `"points": []`）
  - `render_inline(text: str) -> str` — 変更なし
  - `ParseError` — 変更なし
  - `main() -> int` — 変更なし。出力する JS のグローバル変数名は `window.DAILY_NEWS`。Task 2 がこの新しい `{title, intro, points, url}` 形式を読む

- [ ] **Step 1: 既存テストを新スキーマ（`body`→`intro`、`points`追加）に合わせて書き換える**

`tests/test_generate_daily_data.py` の `test_splits_item_into_title_body_and_url` を以下に置き換える（メソッド名も実態に合わせて変更）:

```python
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
```

`test_converts_bold_inside_body` を以下に置き換える（メソッド名も変更）:

```python
    def test_converts_bold_inside_intro(self):
        md = (
            "## 2026-08-01\n"
            "- **見出し**: これは**強調**を含む本文（[出典](https://example.com/b)）。\n"
        )
        intro = parse_daily_markdown(md, "x.md")["2026-08-01"][0]["intro"]
        self.assertEqual(intro, "これは<strong>強調</strong>を含む本文")
```

他のテスト（`test_keeps_multiple_dates_and_item_order`, `test_raises_when_item_has_no_bold_title`, `test_raises_when_item_has_no_source_link`, `test_raises_on_unrecognized_line`, `test_raises_when_item_appears_before_any_date`, `test_title_is_not_rendered_as_strong`, `test_raises_on_invalid_calendar_date`）は `body` キーを直接参照していないためそのまま残す。

- [ ] **Step 2: テストを実行し、新スキーマ関連の2件が失敗することを確認する**

Run: `python3 -m unittest tests.test_generate_daily_data -v`
Expected: `test_splits_item_into_title_intro_points_and_url` と `test_converts_bold_inside_intro` が `KeyError` または `AssertionError` で FAIL。他は現行実装のままなので PASS のまま。

- [ ] **Step 3: 旧形式の出力キーを `body`→`intro`＋`points: []` に変更する**

`scripts/generate_daily_data.py` の `parse_daily_markdown()` 内、`- ` で始まる行を処理するブロック（現行の91〜104行目相当）を以下に置き換える:

```python
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
                    "title": title,
                    "intro": render_inline(SOURCE_RE.sub("", rest).strip()),
                    "points": [],
                    "url": matched_src.group(1),
                }
            )
            continue
```

- [ ] **Step 4: テストを実行し、Step 1で書き換えた2件を含め全件パスすることを確認する**

Run: `python3 -m unittest tests.test_generate_daily_data -v`
Expected: 全件 PASS

- [ ] **Step 5: 新形式パースの失敗するテストを書く**

`tests/test_generate_daily_data.py` の `TestParseDailyMarkdown` クラスに以下を追加する:

```python
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
```

- [ ] **Step 6: テストを実行し、Step 5で追加した7件が失敗することを確認する**

Run: `python3 -m unittest tests.test_generate_daily_data -v`
Expected: Step 5で追加した7件が FAIL（未対応の形式のため既存のcatch-all `ParseError` に落ちるか、意図と異なるメッセージ・値になる）。他は PASS のまま。

- [ ] **Step 7: 新形式パースを実装する**

`scripts/generate_daily_data.py` の正規表現定義（20〜23行目相当）を以下に置き換える:

```python
DATE_RE = re.compile(r"^##\s+(\d{4}-\d{2}-\d{2})\s*$")
ITEM_RE = re.compile(r"^-\s+\*\*(.+?)\*\*[:：]\s*(.+)$")
NEW_HEADER_RE = re.compile(r"^-\s+\*\*(.+?)\*\*\s*[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
POINT_RE = re.compile(r"^・\s*\*\*(.+?)\*\*[:：]\s*(.+)$")
SOURCE_RE = re.compile(r"[（(]\[出典\]\((https?://[^)]+)\)[）)]\s*[。．.]?\s*$")
BOLD_RE = re.compile(r"\*\*(.+?)\*\*")
```

`parse_daily_markdown()` 全体を以下に置き換える（関数シグネチャ・docstringは維持）:

```python
def parse_daily_markdown(text: str, source: str) -> dict:
    """1ファイル分の Markdown を {日付: [項目, ...]} に変換する。

    項目は {"title": str, "intro": str, "points": list[dict], "url": str}。
    旧形式（1行完結）は points が空リストになる。
    同一ファイル内に同じ日付見出しが複数回現れた場合は、1つの日付にマージする。
    想定形式に一致しない行があれば ParseError を送出する。
    """
    result = ParseResult()
    current_date = None
    current_item = None
    seen_dates = set()

    for lineno, raw in enumerate(text.split("\n"), 1):
        line = raw.strip()

        if not line:
            continue

        # ファイル先頭の「# 2026年8月 AIニュースまとめ」は読み飛ばす
        if line.startswith("# "):
            continue

        matched_date = DATE_RE.match(line)
        if matched_date:
            date_str = matched_date.group(1)
            # 書式だけでなく実在する暦日かどうかも検証する
            # (2026-13-45 や 2026-02-31 がカレンダー表示を壊すため)
            try:
                datetime.date.fromisoformat(date_str)
            except ValueError:
                raise ParseError(
                    f"{source}:{lineno}: 実在しない日付です: {line}"
                )
            current_date = date_str
            current_item = None
            if current_date in seen_dates:
                result.duplicate_dates.add(current_date)
            seen_dates.add(current_date)
            result.setdefault(current_date, [])
            continue

        if line.startswith("・"):
            if current_item is None:
                raise ParseError(
                    f"{source}:{lineno}: 見出し行より前に箇条書き行があります: {line}"
                )
            matched_point = POINT_RE.match(line)
            if not matched_point:
                raise ParseError(
                    f"{source}:{lineno}: '・**ラベル**: 説明' の形式ではありません: {line}"
                )
            current_item["points"].append(
                {
                    "label": render_inline(matched_point.group(1).strip()),
                    "text": render_inline(matched_point.group(2).strip()),
                }
            )
            continue

        if line.startswith("- "):
            if current_date is None:
                raise ParseError(
                    f"{source}:{lineno}: 日付見出し(## YYYY-MM-DD)より前に項目行があります: {line}"
                )

            matched_new_header = NEW_HEADER_RE.match(line)
            if matched_new_header:
                current_item = {
                    "title": matched_new_header.group(1).strip(),
                    "intro": None,
                    "points": [],
                    "url": matched_new_header.group(2),
                    "_lineno": lineno,
                }
                result[current_date].append(current_item)
                continue

            matched_item = ITEM_RE.match(line)
            if not matched_item:
                raise ParseError(
                    f"{source}:{lineno}: '- **見出し**: 本文' または "
                    f"'- **見出し**（[出典](URL)）' の形式ではありません: {line}"
                )
            title = matched_item.group(1).strip()
            rest = matched_item.group(2).strip()
            matched_src = SOURCE_RE.search(rest)
            if not matched_src:
                raise ParseError(
                    f"{source}:{lineno}: 末尾の（[出典](URL)）が見つかりません: {line}"
                )
            current_item = {
                "title": title,
                "intro": render_inline(SOURCE_RE.sub("", rest).strip()),
                "points": [],
                "url": matched_src.group(1),
                "_lineno": lineno,
            }
            result[current_date].append(current_item)
            continue

        # 新形式の見出し行に続く導入文（地の文）
        if current_item is None:
            raise ParseError(f"{source}:{lineno}: 解釈できない行です: {line}")
        rendered = render_inline(line)
        if current_item["intro"] is None:
            current_item["intro"] = rendered
        else:
            current_item["intro"] += " " + rendered

    for date, items in result.items():
        for item in items:
            if item["intro"] is None:
                raise ParseError(
                    f"{source}:{item['_lineno']}: 見出し行の次に導入文がありません: {item['title']}"
                )
            del item["_lineno"]

    return result
```

- [ ] **Step 8: テストを実行し、全件パスすることを確認する**

Run: `python3 -m unittest tests.test_generate_daily_data -v`
Expected: 全件 PASS（既存分 + Step 1・Step 5で追加/変更した分）

- [ ] **Step 9: 実データに対する回帰テストが通ることを確認する**

Run: `python3 -m unittest tests.test_generate_daily_data.TestRealData -v`
Expected: PASS（`everyday_news/*.md` は全件旧形式のため、日数・件数が変更前と一致する）

- [ ] **Step 10: コミット**

```bash
git add scripts/generate_daily_data.py tests/test_generate_daily_data.py
git commit -m "$(cat <<'EOF'
generate_daily_data.py: 新形式(導入文+箇条書き)のパースに対応

everyday_news/*.md の項目を title/intro/points/url の統一形式に変換する。
旧形式(1行完結)はpoints:[]として扱い、新旧混在するデータも1本のロジックで処理できるようにした。
EOF
)"
```

---

### Task 2: `history/daily.html` — 導入文＋箇条書きの描画

**Files:**
- Modify: `history/daily.html`

**Interfaces:**
- Consumes: `window.DAILY_NEWS`（Task 1が生成する `history/daily-data.js` の中身）の各項目 `{title: str, intro: str, points: [{label: str, text: str}], url: str}`
- Produces: なし（末端のUIタスク）

- [ ] **Step 1: CSSに箇条書きリストのスタイルを追加する**

`history/daily.html` の `.news-card strong { color: var(--text); }`（257行目相当）の直後に追加する:

```css
.news-card .point-list {
  list-style: none;
  margin-top: 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.news-card .point-list li {
  font-size: 0.83rem;
  color: var(--text-dim);
  line-height: 1.75;
}
```

（`<strong>` の色は既存の `.news-card strong` セレクタが `.point-list li` 内の `<strong>` にもそのまま効く）

- [ ] **Step 2: `renderDay()` を intro + points 対応に書き換える**

`history/daily.html` の `renderDay()` 内、項目ごとのカード生成部分（現行595〜620行目相当）を以下に置き換える:

```javascript
    const kicker = document.createElement('div');
    kicker.className = 'kicker';
    kicker.textContent = hostOf(item.url);

    const h3 = document.createElement('h3');
    h3.textContent = item.title;

    // intro だけは <strong> 強調を許可するため innerHTML を使うが、
    // escapeExceptStrong() でそれ以外の記号を無害化してから渡す。
    const p = document.createElement('p');
    p.innerHTML = escapeExceptStrong(item.intro);

    let pointList = null;
    if (item.points && item.points.length) {
      pointList = document.createElement('ul');
      pointList.className = 'point-list';
      item.points.forEach(pt => {
        const li = document.createElement('li');
        li.innerHTML = '<strong>' + escapeExceptStrong(pt.label) + '</strong>: ' + escapeExceptStrong(pt.text);
        pointList.appendChild(li);
      });
    }

    const a = document.createElement('a');
    a.className = 'card-src';
    a.textContent = '出典を読む →';
    a.target = '_blank';
    a.rel = 'noopener';
    const href = safeHref(item.url);
    if (href) {
      a.href = href;
    } else {
      a.removeAttribute('href');
      a.setAttribute('aria-disabled', 'true');
    }

    if (pointList) {
      article.append(kicker, h3, p, pointList, a);
    } else {
      article.append(kicker, h3, p, a);
    }
```

（`item.body` を参照していた箇所が `item.intro` に変わる点、および `pointList` の有無で `article.append(...)` の引数を出し分ける点が変更点。それ以外の行 — `article` 生成、フェードイン処理等 — は変更しない）

- [ ] **Step 3: コミット**

```bash
git add history/daily.html
git commit -m "$(cat <<'EOF'
daily.html: カードに導入文+箇条書き解説を描画

generate_daily_data.pyが生成する intro/points をカードに表示する。
旧形式データ(points:[])は従来通り見出し+1段落のみの表示になる。
EOF
)"
```

（動作確認はTask 4でまとめて行う）

---

### Task 3: `scripts/daily_news_prompt.txt` — 新フォーマットの記述指示

**Files:**
- Modify: `scripts/daily_news_prompt.txt`

**Interfaces:**
- Consumes: なし（自動化ジョブのプロンプト文面。Task 1のパーサーが期待する形式と一致させる）
- Produces: なし（末端のドキュメントタスク）

- [ ] **Step 1: 手順5を新フォーマットの記述に置き換える**

`scripts/daily_news_prompt.txt` の手順5（13〜18行目）を以下に置き換える:

```
5. ファイル末尾（既存内容は残したまま）に、以下の形式で今日の日付の見出しを追記する:

## <YYYY-MM-DD>

- **【<カテゴリ>】<見出し：出来事＋現象名。結論や驚きを一目で伝える>**（[出典](URL)）
  <1〜2文の導入文。いつ・どこで・何が起きたかを俯瞰する>
  ・**<小見出しA>**: <説明1〜2文>
  ・**<小見出しB>**: <説明1〜2文>
  ・**<小見出しC>**: <説明1〜2文>（任意。2〜3個が目安）
- **【<カテゴリ>】<次の項目の見出し>**（[出典](URL)）
  ...
```

- [ ] **Step 2: 手順6を書き方の観点説明に置き換える**

`scripts/daily_news_prompt.txt` の手順6（20行目）を以下に置き換える:

```
6. 各項目は次の観点で書くこと。
   - 見出しは単なる要約ではなく「【カテゴリ】＋出来事＋現象名」とし、結論や驚きを一目で伝える（カテゴリの語彙例は手順8のLINE通知文にある例と揃える。技術／資金調達／産業／規制など、内容に応じて選ぶ）。
   - 導入文は1〜2文で、いつ・どこで・何が起きたかを俯瞰する。前置きを長くしない。
   - 箇条書き解説は2〜3個。各箇条は背景・具体的な仕組みや数字・業界への影響など異なる角度から書き、無理に個数を埋めて薄い内容を書かないこと。ラベルは「背景」「現状」「重要性」「影響」「今後の展望」など内容に一番合う言葉をそのつど選ぶ（固定の語彙に縛られなくてよい）。
   - 全体は日本語で、簡潔かつ事実ベースで書くこと。
```

- [ ] **Step 3: 手順9のエラー時ガイダンス文言を更新する**

`scripts/daily_news_prompt.txt` の手順9内、異常終了時の説明文（現行35行目）を以下に置き換える:

```
   - スクリプトが異常終了した場合（終了コードが0以外）は、`everyday_news/<YYYYMM>.md` に書いた内容が想定形式（見出し行 `- **見出し**（[出典](URL)）` ＋ 導入文の行 ＋ `・**ラベル**: 説明` の箇条書き行、という3行種の並び）から外れている。コミット・pushは行わず、stderrに出たファイル名・行番号の該当行を手順5の形式に直してから、もう一度このスクリプトを実行する。直しても通らない場合は、コミットせずに手順10へ進み、SUMMARYにその旨を書く。
```

- [ ] **Step 4: 差分を確認する**

Run: `git diff scripts/daily_news_prompt.txt`
Expected: 手順5・6・9のみが変更されており、手順1〜4・7・8・10は無変更であること

- [ ] **Step 5: コミット**

```bash
git add scripts/daily_news_prompt.txt
git commit -m "$(cat <<'EOF'
daily_news_prompt.txt: サイト記事の新フォーマットを指示

手順5・6をgenerate_daily_data.pyの新パース形式(見出し+導入文+箇条書き)に合わせて更新。
手順9のエラーガイダンス文言も新形式に合わせて修正。LINE通知文(手順8)は変更なし。
EOF
)"
```

---

### Task 4: エンドツーエンド検証

**Files:**
- Temporarily modify (revert before finishing): `everyday_news/202608.md`
- Regenerate (revert before finishing): `history/daily-data.js`

**Interfaces:**
- Consumes: Task 1〜3の全成果物
- Produces: なし（検証のみ。コードやデータへの恒久的な変更は行わない）

- [ ] **Step 1: テストスイート全体を実行する**

Run: `python3 -m unittest discover -s tests -v`
Expected: 全件 PASS

- [ ] **Step 2: 実データに対する回帰実行**

Run: `python3 scripts/generate_daily_data.py`
Expected: 終了コード0、stderrに`警告:`が出ない、出力に`generated .../daily-data.js (N days, M items)`が表示される。直前の`git diff --stat history/daily-data.js`が空（内容が変わっていない）ことも確認する。

- [ ] **Step 3: 新形式の項目を一時的に追記する**

`everyday_news/202608.md` の `## 2026-08-11` セクション末尾（既存の最後の項目「カリフォルニア州、AIを活用した『AIサイバー防衛プログラム』を始動」の直後）に、Editツールで以下を一時的に追記する:

```
- **【検証用】これはUI確認用の一時テスト項目です**（[出典](https://example.com/verification-only)）
  検証用に追加した導入文です。UI確認後にこの項目は削除します。
  ・**背景**: 検証用のダミーテキストです。
  ・**影響**: この項目は確認後に削除され、コミットには含まれません。
```

- [ ] **Step 4: 一時データでスクリプトを再実行する**

Run: `python3 scripts/generate_daily_data.py`
Expected: 終了コード0。`history/daily-data.js` に `"2026-08-11"` の配列末尾として `points` が2件入った項目が追加されていることを、生成後のファイルを読んで確認する。

- [ ] **Step 5: ブラウザで表示を確認する**

ToolSearchで `mcp__claude-in-chrome__tabs_context_mcp`, `navigate`, `computer`, `tabs_create_mcp`, `tabs_close_mcp` をロードし、`history/daily.html` をローカルで開く（`file://` パス、またはリポジトリに簡易HTTPサーバがあればそちら）。2026-08-11のカードを開き、以下をスクリーンショットで確認する:
- 追記した検証用カードに、導入文の下に「背景」「影響」の箇条書きラベル付きリストが表示される
- 同じ日にある他の既存カード（旧形式）は従来通り見出し＋1段落のみで、箇条書きが出ない
- ウィンドウ幅を375px相当に縮小またはモバイル表示で確認し、箇条書きが崩れずに読めることを確認する

- [ ] **Step 6: 検証用スクリーンショットを削除する**

確認が完了したスクリーンショットファイルを削除する（グローバルCLAUDE.mdの方針により、claude-in-chromeでの動作確認用スクリーンショットは確認後にユーザー確認なしで削除してよい）。

- [ ] **Step 7: エラー系（意図的に壊した新形式）の手動確認**

Bashで一時ファイルを作り、新形式の見出し行の直後に導入文を書かずに`・`行だけを続けた場合と、`・`ラベルを太字にし忘れた場合の2パターンを試す:

```bash
cd "/Users/motoki/Desktop/GitHub/03_自動化・定期実行/ai_news"
python3 -c "
import sys
sys.path.insert(0, 'scripts')
from generate_daily_data import parse_daily_markdown, ParseError

# パターン1: 導入文なしでいきなり箇条書き
md1 = '## 2026-08-01\n- **見出し**（[出典](https://example.com/a)）\n  ・**ラベル**: 説明。\n'
try:
    parse_daily_markdown(md1, 'test.md')
    print('NG: エラーになりませんでした')
except ParseError as e:
    print('OK:', e)

# パターン2: 箇条書きのラベルが太字でない
md2 = '## 2026-08-01\n- **見出し**（[出典](https://example.com/a)）\n  導入文。\n  ・ラベル: 説明。\n'
try:
    parse_daily_markdown(md2, 'test.md')
    print('NG: エラーになりませんでした')
except ParseError as e:
    print('OK:', e)
"
```

Expected: 両パターンとも `OK:` で始まる行が出力され、`ParseError`が正しく送出されること（これは`tests/test_generate_daily_data.py`のStep 5で自動テスト済みの内容と同じだが、実際のCLI実行経路でも同様に機能することを目視確認する）

- [ ] **Step 8: 一時的な変更を元に戻す**

Editツールで、Step 3で `everyday_news/202608.md` に追記した検証用の4行（見出し行・導入文行・箇条書き2行）を削除する。

- [ ] **Step 9: `daily-data.js` を元の内容に再生成する**

Run: `python3 scripts/generate_daily_data.py`
Expected: 終了コード0。`git diff --stat everyday_news/202608.md history/daily-data.js` が両方とも空（変更なし）であることを確認する。

- [ ] **Step 10: 作業ツリーがクリーンであることを確認する**

Run: `git status`
Expected: `nothing to commit, working tree clean`（Task 1〜3のコミット以降、新たな差分が残っていないこと）
