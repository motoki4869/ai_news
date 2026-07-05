# news.html 継続更新の仕組み化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `report/` に追加される調査レポートを `history/news.html` へ反映する作業を、Claude Code スキルとして標準化し、カード増加時に `history/archive.html` へ循環させる仕組みを作る。

**Architecture:** (1) 既存の `history/news.html` の全 `.news-card` に `data-added` / `data-report` のメタデータ属性を後付けする、(2) `history/news.html` ⇔ `history/archive.html` の双方向ナビゲーションを追加する、(3) 過去ログ用の空の `history/archive.html` を新設する、(4) `.claude/skills/sync-news-html/SKILL.md` として更新手順そのものを1つのスキルにまとめる。すべて静的HTML+手順書であり、ビルドツールやテストランナーは使わない。

**Tech Stack:** 素のHTML/CSS/JS（フレームワークなし）、Python3（一回限りのメタデータ付与スクリプト。恒久的なツールとしては残さない）、Claude Code スキル（Markdown）。

## Global Constraints

- 対象プロジェクトは `/Users/motoki/Desktop/GitHub/ai_news`（独立したgitリポジトリ）。すべてのファイルパスはここからの相対パス。
- `history/news.html` の固定7テーマ: `#agent` `#japan` `#physical` `#sovereign` `#infra` `#society` `#security`。新しいテーマは追加しない。
- 各セクションの `.news-card` 上限は **6枚**。超過時は最も古いカードを `history/archive.html` へ循環。
- 各 `.news-card` は `data-added="YYYY-MM-DD"` と `data-report="ファイル名"` を持つ。
- 更新トリガーは手動呼び出しのみ（自動検知・スケジューラは対象外）。
- 重複ニュースは新規カードを作らず、既存カードの `.src` 表示テキストと `data-report` 属性の両方にレポート名を追記する。
- 変更は各ファイルへの直接上書き保存。git管理下のため差分はコミット単位で追跡する。

---

### Task 1: `history/news.html` の既存カードに `data-added` / `data-report` を後付けする

**Files:**
- Modify: `history/news.html`（34個の `.news-card` 開始タグ）

**Interfaces:**
- Consumes: なし（このタスクが起点）
- Produces: すべての `.news-card` が `data-added="2026-07-05"` と `data-report="(元の.srcテキスト)"` 属性を持つ状態。Task 3 のスキルはこの属性がある前提で「最も古いカード」を判定する。

- [ ] **Step 1: 現状のカード数を確認する**

Run:
```bash
cd /Users/motoki/Desktop/GitHub/ai_news
grep -c '<div class="news-card">' history/news.html
```
Expected: `34`

- [ ] **Step 2: 一回限りのメタデータ付与スクリプトを作成する**

Create a temporary script at `/private/tmp/claude-501/-Users-motoki-Desktop-GitHub/13f5410f-61ca-4271-945b-011385837bce/scratchpad/add_card_meta.py`（コミットしない、一回限りの変換用）:

```python
import re
import pathlib

path = pathlib.Path("/Users/motoki/Desktop/GitHub/ai_news/history/news.html")
text = path.read_text(encoding="utf-8")

pattern = re.compile(
    r'<div class="news-card">(.*?)<div class="src">(.*?)</div>(\s*)</div>',
    re.DOTALL,
)

def repl(m):
    body, src, trailing_ws = m.group(1), m.group(2), m.group(3)
    src_escaped = src.replace('"', "&quot;")
    return (
        f'<div class="news-card" data-added="2026-07-05" '
        f'data-report="{src_escaped}">{body}'
        f'<div class="src">{src}</div>{trailing_ws}</div>'
    )

new_text, count = pattern.subn(repl, text)
assert count == 34, f"expected 34 cards, got {count}"
path.write_text(new_text, encoding="utf-8")
print(f"updated {count} cards")
```

- [ ] **Step 3: スクリプトを実行する**

Run:
```bash
python3 /private/tmp/claude-501/-Users-motoki-Desktop-GitHub/13f5410f-61ca-4271-945b-011385837bce/scratchpad/add_card_meta.py
```
Expected output: `updated 34 cards`

- [ ] **Step 4: 属性が正しく付与されたか検証する**

Run:
```bash
cd /Users/motoki/Desktop/GitHub/ai_news
grep -c 'data-added="2026-07-05"' history/news.html
grep -c 'data-report="' history/news.html
```
Expected: 両方とも `34`

- [ ] **Step 5: HTMLとして壊れていないか目視確認する**

Run:
```bash
python3 - <<'EOF'
import re
text = open("/Users/motoki/Desktop/GitHub/ai_news/history/news.html", encoding="utf-8").read()
opens = len(re.findall(r'<div class="news-card"', text))
grids = re.findall(r'<div class="news-grid">.*?</div>\s*</section>', text, re.DOTALL)
print("news-card opens:", opens)
print("news-grid blocks found:", len(grids))
EOF
```
Expected: `news-card opens: 34`、`news-grid blocks found: 7`（7セクション分）

- [ ] **Step 6: Commit**

```bash
cd /Users/motoki/Desktop/GitHub/ai_news
git add history/news.html
git commit -m "news.htmlの既存カードにdata-added/data-report属性を付与"
```

---

### Task 2: `history/news.html` から `history/archive.html` への導線を追加する

**Files:**
- Modify: `history/news.html:365-378`（`nav-links` ブロック）
- Modify: `history/news.html:311-332`（`.cta-back` CSS ブロック）
- Modify: `history/news.html:707-710`（`.cta-back` HTML ブロック）

**Interfaces:**
- Consumes: なし
- Produces: `history/news.html` から `history/archive.html` へのリンクが2箇所（ナビゲーション・下部CTA）に存在する状態。Task 3 で作る `history/archive.html` はこのリンク先として実在している前提。

- [ ] **Step 1: nav-links に過去ログへのリンクを追加する**

`history/news.html` の以下の箇所を編集する:

Before:
```html
  <div class="nav-links">
    <a href="#agent">エージェント</a>
    <a href="#japan">国内実装</a>
    <a href="#physical">フィジカルAI</a>
    <a href="#sovereign">ソブリンAI</a>
    <a href="#infra">インフラ</a>
    <a href="#society">経済・社会</a>
    <a href="#security">セキュリティ</a>
    <a class="back-btn" href="index.html">← AI HISTORY</a>
  </div>
```

After:
```html
  <div class="nav-links">
    <a href="#agent">エージェント</a>
    <a href="#japan">国内実装</a>
    <a href="#physical">フィジカルAI</a>
    <a href="#sovereign">ソブリンAI</a>
    <a href="#infra">インフラ</a>
    <a href="#society">経済・社会</a>
    <a href="#security">セキュリティ</a>
    <a href="archive.html">過去ログ</a>
    <a class="back-btn" href="index.html">← AI HISTORY</a>
  </div>
```

- [ ] **Step 2: `.cta-back` の CSS に `to-archive` のスタイルを追加する**

Before:
```css
.cta-back a.to-gen {
  color: var(--magenta);
  border: 1px solid rgba(255,46,230,0.4);
  background: rgba(255,46,230,0.05);
}
.cta-back a.to-gen:hover { box-shadow: 0 0 26px rgba(255,46,230,0.4); transform: translateY(-2px); }
```

After:
```css
.cta-back a.to-gen {
  color: var(--magenta);
  border: 1px solid rgba(255,46,230,0.4);
  background: rgba(255,46,230,0.05);
}
.cta-back a.to-gen:hover { box-shadow: 0 0 26px rgba(255,46,230,0.4); transform: translateY(-2px); }
.cta-back a.to-archive {
  color: var(--amber);
  border: 1px solid rgba(255,181,71,0.4);
  background: rgba(255,181,71,0.05);
}
.cta-back a.to-archive:hover { box-shadow: 0 0 26px rgba(255,181,71,0.4); transform: translateY(-2px); }
```

- [ ] **Step 3: `.cta-back` の HTML に過去ログへのリンクを追加する**

Before:
```html
  <div class="cta-back">
    <a class="to-index" href="index.html">← AI HISTORY 全体年表</a>
    <a class="to-gen" href="generative.html">生成AIの時代 詳細年表 →</a>
  </div>
```

After:
```html
  <div class="cta-back">
    <a class="to-index" href="index.html">← AI HISTORY 全体年表</a>
    <a class="to-gen" href="generative.html">生成AIの時代 詳細年表 →</a>
    <a class="to-archive" href="archive.html">過去ログを見る →</a>
  </div>
```

- [ ] **Step 4: リンクが2箇所とも存在することを確認する**

Run:
```bash
cd /Users/motoki/Desktop/GitHub/ai_news
grep -c 'href="archive.html"' history/news.html
```
Expected: `2`

- [ ] **Step 5: Commit**

```bash
cd /Users/motoki/Desktop/GitHub/ai_news
git add history/news.html
git commit -m "news.htmlにarchive.htmlへの導線を追加"
```

---

### Task 3: `history/archive.html` を新規作成する

**Files:**
- Create: `history/archive.html`

**Interfaces:**
- Consumes: `history/news.html` の `:root` CSS変数（`--bg` `--green` `--cyan` `--violet` `--amber` `--coral` `--blue` `--magenta` `--text` `--text-dim` `--card` `--border`）と同じ配色を踏襲する。
- Produces: id `agent` `japan` `physical` `sovereign` `infra` `society` `security` を持つ7つの `<section class="section t-XXX">` ブロック。各 `.news-grid` は空で `<p class="archive-empty">まだアーカイブされたカードはありません。</p>` を1つ持つ。Task 4 のスキルはこの構造（idとnews-grid）に対してカードを追加/削除する。

- [ ] **Step 1: `history/archive.html` を作成する**

```html
<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>AI NEWS ARCHIVE — 過去ログ</title>
<meta name="description" content="history/news.htmlから循環した過去のAIニューストピックのアーカイブ。">
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
  line-height: 1.8;
}

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
  background: linear-gradient(90deg, var(--amber), var(--coral));
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

.hero {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  text-align: center; padding: 140px 24px 50px;
}
.hero-tag {
  font-family: 'JetBrains Mono', monospace; font-size: 0.8rem;
  color: var(--amber);
  border: 1px solid rgba(255,181,71,0.4); border-radius: 999px;
  padding: 6px 20px; margin-bottom: 20px;
  background: rgba(255,181,71,0.06);
}
.hero h1 {
  font-family: 'Orbitron', sans-serif; font-weight: 800;
  font-size: clamp(1.6rem, 5vw, 3rem);
  letter-spacing: 0.1em;
  background: linear-gradient(120deg, var(--amber) 0%, var(--coral) 100%);
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
}
.hero h2 {
  margin-top: 14px; font-weight: 300;
  font-size: clamp(0.85rem, 2vw, 1.1rem);
  color: var(--text-dim); letter-spacing: 0.2em;
}

.section { max-width: 1100px; margin: 0 auto; padding: 50px 24px 10px; scroll-margin-top: 40px; }
.section-header { margin-bottom: 34px; display: flex; align-items: baseline; gap: 16px; flex-wrap: wrap; }
.sec-no { font-family: 'Orbitron', sans-serif; font-weight: 800; font-size: 1.9rem; opacity: 0.9; }
.section-header h2 {
  font-family: 'Orbitron', 'Noto Sans JP', sans-serif;
  font-size: clamp(1.2rem, 3.2vw, 1.7rem); font-weight: 600; letter-spacing: 0.05em;
}
.section-header .sec-line { flex: 1; height: 1px; min-width: 60px; }

.t-agent .sec-no, .t-agent h2 { color: var(--green); }
.t-agent .sec-line { background: linear-gradient(90deg, rgba(0,255,163,0.6), transparent); }
.t-japan .sec-no, .t-japan h2 { color: var(--amber); }
.t-japan .sec-line { background: linear-gradient(90deg, rgba(255,181,71,0.6), transparent); }
.t-physical .sec-no, .t-physical h2 { color: var(--violet); }
.t-physical .sec-line { background: linear-gradient(90deg, rgba(139,92,246,0.6), transparent); }
.t-sovereign .sec-no, .t-sovereign h2 { color: var(--blue); }
.t-sovereign .sec-line { background: linear-gradient(90deg, rgba(92,157,255,0.6), transparent); }
.t-infra .sec-no, .t-infra h2 { color: var(--cyan); }
.t-infra .sec-line { background: linear-gradient(90deg, rgba(0,229,255,0.6), transparent); }
.t-society .sec-no, .t-society h2 { color: var(--magenta); }
.t-society .sec-line { background: linear-gradient(90deg, rgba(255,46,230,0.6), transparent); }
.t-security .sec-no, .t-security h2 { color: var(--coral); }
.t-security .sec-line { background: linear-gradient(90deg, rgba(255,122,92,0.6), transparent); }

.news-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(310px, 1fr)); gap: 18px; }
.news-card {
  background: var(--card);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 12px; padding: 22px 24px;
  display: flex; flex-direction: column;
}
.news-card .kicker { font-family: 'JetBrains Mono', monospace; font-size: 0.66rem; letter-spacing: 0.15em; margin-bottom: 6px; }
.t-agent .kicker { color: var(--green); }
.t-japan .kicker { color: var(--amber); }
.t-physical .kicker { color: #b79bff; }
.t-sovereign .kicker { color: var(--blue); }
.t-infra .kicker { color: var(--cyan); }
.t-society .kicker { color: var(--magenta); }
.t-security .kicker { color: var(--coral); }
.news-card h3 { font-size: 1rem; font-weight: 700; margin-bottom: 8px; line-height: 1.55; }
.news-card p { font-size: 0.83rem; color: var(--text-dim); line-height: 1.75; flex: 1; }
.src {
  margin-top: 14px;
  font-family: 'JetBrains Mono', monospace; font-size: 0.64rem;
  color: var(--text-dim); letter-spacing: 0.04em;
  border-top: 1px dashed rgba(255,255,255,0.12);
  padding-top: 10px;
}
.src::before { content: '📄 SOURCE: '; color: rgba(255,255,255,0.35); }

.archive-empty { color: var(--text-dim); font-size: 0.85rem; grid-column: 1 / -1; }

.cta-back { text-align: center; padding: 60px 24px 100px; display: flex; gap: 18px; justify-content: center; flex-wrap: wrap; }
.cta-back a {
  display: inline-block;
  font-family: 'JetBrains Mono', monospace; font-size: 0.85rem;
  text-decoration: none;
  border-radius: 999px;
  padding: 12px 34px;
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
  background: linear-gradient(90deg, var(--amber), var(--coral));
  -webkit-background-clip: text; background-clip: text;
  -webkit-text-fill-color: transparent;
  margin-bottom: 8px; font-size: 0.95rem;
}

@media (max-width: 768px) {
  .nav-links a:not(.back-btn) { display: none; }
  .hero { padding-top: 120px; }
}
</style>
</head>
<body>

<nav>
  <div class="nav-logo">AI NEWS ARCHIVE</div>
  <div class="nav-links">
    <a class="back-btn" href="news.html">← NEWS FEED</a>
  </div>
</nav>

<header class="hero">
  <div class="hero-tag">ARCHIVE — 過去ログ</div>
  <h1>AI NEWS ARCHIVE</h1>
  <h2>news.htmlから循環した過去のトピック</h2>
</header>

<section class="section t-agent" id="agent">
  <div class="section-header">
    <span class="sec-no">01</span>
    <h2>エージェンティックAI — SaaSの次へ</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-japan" id="japan">
  <div class="section-header">
    <span class="sec-no">02</span>
    <h2>国内企業の実装最前線</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-physical" id="physical">
  <div class="section-header">
    <span class="sec-no">03</span>
    <h2>フィジカルAI — 物理世界への進出</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-sovereign" id="sovereign">
  <div class="section-header">
    <span class="sec-no">04</span>
    <h2>ソブリンAI — 国家戦略としてのAI</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-infra" id="infra">
  <div class="section-header">
    <span class="sec-no">05</span>
    <h2>インフラ・半導体 — 物理的限界との戦い</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-society" id="society">
  <div class="section-header">
    <span class="sec-no">06</span>
    <h2>経済・社会・働き方の再定義</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<section class="section t-security" id="security">
  <div class="section-header">
    <span class="sec-no">07</span>
    <h2>セキュリティ・ガバナンス</h2>
    <span class="sec-line"></span>
  </div>
  <div class="news-grid">
    <p class="archive-empty">まだアーカイブされたカードはありません。</p>
  </div>
</section>

<div class="cta-back">
  <a class="to-news" href="news.html">← NEWS FEED に戻る</a>
  <a class="to-index" href="index.html">AI HISTORY 全体年表 →</a>
</div>

<footer>
  <div class="logo">AI NEWS ARCHIVE</div>
  <div>CIRCULATED FROM history/news.html</div>
</footer>

</body>
</html>
```

- [ ] **Step 2: 7セクションすべてが存在することを検証する**

Run:
```bash
cd /Users/motoki/Desktop/GitHub/ai_news
for id in agent japan physical sovereign infra society security; do
  grep -c "id=\"$id\"" history/archive.html
done
```
Expected: `1` が7行(各テーマ1回ずつ)

- [ ] **Step 3: news.html からの導線が実際に開けることをブラウザで確認する**

`history/news.html` をブラウザで開き、ナビゲーションの「過去ログ」リンクと下部の「過去ログを見る →」リンクをクリックし、`history/archive.html` が正しく表示されること、および `archive.html` 側の「← NEWS FEED に戻る」で `news.html` に戻れることを目視確認する。

- [ ] **Step 4: Commit**

```bash
cd /Users/motoki/Desktop/GitHub/ai_news
git add history/archive.html
git commit -m "過去ログページhistory/archive.htmlを新規作成"
```

---

### Task 4: `sync-news-html` スキルを作成する

**Files:**
- Create: `.claude/skills/sync-news-html/SKILL.md`

**Interfaces:**
- Consumes: Task 1〜3で用意した `data-added` / `data-report` 属性、`history/archive.html` の7セクション構造とnav導線。
- Produces: `report/*.md` を指定して呼び出せる新スキル。既存の `format-report` スキルと同じ発見のされ方（`description` に日本語トリガー文言を含める）。

- [ ] **Step 1: SKILL.md を作成する**

```markdown
---
name: sync-news-html
description: report/配下の調査レポート1本をhistory/news.htmlに反映する。カード上限(6枚/セクション)を超えたら最も古いカードをhistory/archive.htmlへ循環させる。ユーザーが「このreportをnews.htmlに反映して」「news.html更新して」等と依頼したときに使う。
---

# ai_news news.html 継続更新

## 対象ファイル
- 入力: `report/*.md`。ユーザーが対象を指定しなければ、`report/` 内で最終更新日時が最も新しいファイルを対象にする。
- 出力: `history/news.html`(メイン)、`history/archive.html`(循環先)。

## 前提
- `history/news.html` は7つの固定テーマセクションを持つ: `#agent`(エージェンティックAI) `#japan`(国内実装) `#physical`(フィジカルAI) `#sovereign`(ソブリンAI) `#infra`(インフラ) `#society`(経済・社会) `#security`(セキュリティ)。新しいテーマは追加しない。
- 各セクションの `.news-card` 上限は6枚。
- 各 `.news-card` は `data-added="YYYY-MM-DD"`(追加日)と `data-report="ファイル名"`(出典)を持つ。
- `history/archive.html` は同じ7テーマ・同じidを持つ「過去ログ」ページ。カード循環時のみ更新する。

## 手順

1. 対象レポートを全文読む。改行のない一塊の文章で読みにくい場合は、先に `format-report` スキルを適用してから次に進む。
2. レポート内から news-card 化すべきトピックを洗い出す。固有名詞・具体的な数字を含む「見出しになる」情報を優先し、抽象的な一般論は避ける。
3. 洗い出した各トピックを、既存7テーマのうち最も近いものに割り当てる。無理に当てはまらない場合も、最も近いテーマに寄せる(新テーマは作らない)。
4. 重複判定: `history/news.html` の全 `.news-card` を確認し、同一企業・同一イベントを指すカードが既にあれば、新規カードは作らない。代わりに、そのカードの `.src` 表示テキストと `data-report` 属性の両方に、今回のレポートのファイル名を " / " 区切りで追記する。
5. 重複しないトピックは、該当セクションの `.news-grid` 末尾に新規 `.news-card` として追加する。書式:
   ```html
   <div class="news-card" data-added="YYYY-MM-DD" data-report="レポートファイル名">
     <div class="kicker">英大文字の短いラベル</div>
     <h3>数字や固有名詞を含む具体的な見出し</h3>
     <p>背景・数字・固有名詞を含む3〜4文の説明。</p>
     <div class="src">レポートファイル名</div>
   </div>
   ```
   - `data-added` は本日日付(YYYY-MM-DD)。
   - kicker/見出し/説明文の文体・トーンは既存カードの書きぶり(断定調、具体的な数字・固有名詞を含む、体言止めや「〜へ」で終わる見出し)に合わせる。要約・推測で内容を水増ししない。
6. カードを追加した各セクションについて `.news-card` の数を数える。6枚を超えていれば、そのセクション内で `data-added` が最も古いカードを1枚選び:
   - `history/news.html` の該当セクションから削除する。
   - `history/archive.html` の同じ id を持つセクションの `.news-grid` に追加する。既存の `archive-empty` プレースホルダー(`<p class="archive-empty">まだアーカイブされたカードはありません。</p>`)があれば、そのセクションから削除してからカードを追加する。
7. `history/news.html` の `hero-desc` 内「調査レポートN本を横断」と footer の「COMPILED FROM N RESEARCH REPORTS」の N を、`report/` 配下の実ファイル数(`ls report/*.md | wc -l` 相当)に更新する。
8. `.ticker` 内のテキストを更新する。今回追加した新規カードの見出しを要約したブレイキングニュース文を1〜2件、末尾に ` +++ ` 区切りで追記する。区切り件数が8件を超える場合は先頭(最も古い)の項目から削除し、総数をおおむね8件に保つ。
9. `history/news.html`(および循環が発生した場合は `history/archive.html`)を上書き保存する。
10. 作業内容を1〜2文で要約報告する: 追加したカード(セクション名・見出し)、循環して `history/archive.html` に移したカード、更新した統計値(レポート本数)。ファイル全文は貼り直さない。
```

- [ ] **Step 2: スキルファイルが存在し、YAML frontmatterが妥当か確認する**

Run:
```bash
cd /Users/motoki/Desktop/GitHub/ai_news
head -n 4 .claude/skills/sync-news-html/SKILL.md
```
Expected: `---` `name: sync-news-html` `description: ...` `---` の4行が表示される

- [ ] **Step 3: Commit**

```bash
cd /Users/motoki/Desktop/GitHub/ai_news
git add .claude/skills/sync-news-html/SKILL.md
git commit -m "sync-news-htmlスキルを追加"
```

---

## Self-Review Notes

- **Spec coverage:** 発火条件・入力(Task4手順1)、抽出/分類/重複判定(Task4手順2-5)、カード上限・循環・archive連携(Task1のメタデータ + Task3のarchive.html + Task4手順6)、ナビゲーション追加(Task2、ユーザー追加要望)、統計値・ティッカー同期(Task4手順7-8)、変更報告(Task4手順10)——すべて対応済み。データ層(JSON化)や自動検知トリガーは設計書で明示的に対象外としたため、プランにも含めていない。
- **Placeholder scan:** 全ステップに実行可能なコマンド・完全なHTML/コード片を記載。「TODO」「後で」等は含まない。
- **Type consistency:** `data-added` / `data-report` の属性名・値の形式(YYYY-MM-DD、ファイル名文字列)はTask1・Task4で一致。`.news-grid` / `.news-card` / セクションid(`agent` `japan` `physical` `sovereign` `infra` `society` `security`)もTask3・Task4で一致。
