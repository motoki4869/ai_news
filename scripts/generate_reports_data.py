#!/usr/bin/env python3
"""report/*.md を丸ごと変換し、history/reports/ 配下の全文データを再生成する。
news.html / archive.html の news-card タップ時モーダル表示用データ。
sync-news-html スキルの一手順として、レポート追加のたびに全件再生成する想定。

レポート1本につきJSONを1ファイル出す。ページ側はタップされた1本だけを fetch し、
読まれない分は転送しない。日本語のレポート名とファイル名の対応表は
history/reports-index.js に別途書き出す（詳細は report_id() のコメント）。
"""
import hashlib
import html
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
REPORT_DIR = REPO_ROOT / "report"
OUT_DIR = REPO_ROOT / "history" / "reports"
INDEX_FILE = REPO_ROOT / "history" / "reports-index.js"


def inline(text: str) -> str:
    text = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", text)
    return text


def parse_table(lines: list[str]) -> str:
    rows = [l.strip() for l in lines if l.strip().startswith("|")]
    # 区切り行(|---|---|)を除去
    rows = [r for r in rows if not re.fullmatch(r"\|[\s:\-|]+\|?", r)]
    cells = [[c.strip() for c in r.strip("|").split("|")] for r in rows]
    if not cells:
        return ""
    head, *body = cells
    out = ['<table class="rpt-table">', "<thead><tr>"]
    out += [f"<th>{inline(c)}</th>" for c in head]
    out.append("</tr></thead><tbody>")
    for row in body:
        out.append("<tr>" + "".join(f"<td>{inline(c)}</td>" for c in row) + "</tr>")
    out.append("</tbody></table>")
    return "".join(out)


def md_to_html(md: str) -> str:
    lines = md.split("\n")
    out = []
    i = 0
    list_buf: list[str] = []

    def flush_list():
        if list_buf:
            out.append("<ul>" + "".join(f"<li>{inline(x)}</li>" for x in list_buf) + "</ul>")
            list_buf.clear()

    while i < len(lines):
        line = lines[i].rstrip()
        stripped = line.strip()

        if not stripped:
            flush_list()
            i += 1
            continue

        if stripped == "---":
            flush_list()
            out.append("<hr>")
            i += 1
            continue

        if stripped.startswith("|"):
            flush_list()
            table_lines = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                table_lines.append(lines[i])
                i += 1
            out.append(parse_table(table_lines))
            continue

        if stripped.startswith("```"):
            flush_list()
            i += 1
            block = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                block.append(lines[i])
                i += 1
            i += 1  # 閉じ```を読み飛ばす
            block_text = html.escape("\n".join(block))
            out.append(f'<pre class="rpt-pre">{block_text}</pre>')
            continue

        if stripped.startswith("$$"):
            flush_list()
            closing_idx = stripped.find("$$", 2)
            if closing_idx != -1:
                # 開始・終了の $$ が同一行にある単一行formula
                out.append(f'<div class="rpt-formula">$${stripped[2:closing_idx].strip()}$$</div>')
                i += 1
                continue
            formula = [stripped.lstrip("$")]
            i += 1
            while i < len(lines) and "$$" not in lines[i]:
                formula.append(lines[i].strip())
                i += 1
            if i < len(lines):
                formula.append(lines[i].strip().rstrip("$"))
                i += 1
            out.append(f'<div class="rpt-formula">$${"".join(f for f in formula if f)}$$</div>')
            continue

        m = re.match(r"^(#{1,4})\s+(.*)$", stripped)
        if m:
            flush_list()
            level = min(len(m.group(1)) + 1, 4)  # 元#1→h2, ##→h2, ###→h3, ####→h4
            if len(m.group(1)) == 1:
                level = 2
            else:
                level = min(len(m.group(1)) + 1, 4)
            out.append(f"<h{level}>{inline(m.group(2))}</h{level}>")
            i += 1
            continue

        if stripped.startswith("- ") or stripped.startswith("* "):
            list_buf.append(stripped[2:].strip())
            i += 1
            continue

        flush_list()
        out.append(f"<p>{inline(stripped)}</p>")
        i += 1

    flush_list()
    return "\n".join(out)


def report_id(key: str) -> str:
    """レポート名（拡張子なしファイル名）から、配信用ファイル名のIDを決める。

    レポート名は日本語を含むので、そのままURLのパスにはしない。macOSのファイル
    システムとGit・配信サーバーとでUnicodeの正規化（NFC/NFD）が食い違うと、
    見た目が同じ名前なのに404になることがあるため。名前のSHA-1から作ったASCIIの
    IDをファイル名にし、日本語名を持つのは対応表（reports-index.js）だけにする。

    連番ではなくハッシュなので、レポートを1本足しても既存のファイル名は変わらない
    （連番だと日付順に差し込むたびに以降が全部ずれ、毎回全ファイルがgitの差分に出る）。
    """
    return hashlib.sha1(key.encode("utf-8")).hexdigest()[:12]


def main():
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    index = {}
    generated = set()
    for path in sorted(REPORT_DIR.glob("*.md")):
        key = path.stem
        file_id = report_id(key)
        index[key] = file_id
        payload = json.dumps(
            {"name": key, "html": md_to_html(path.read_text(encoding="utf-8"))},
            ensure_ascii=False,
        ) + "\n"
        out_path = OUT_DIR / f"{file_id}.json"
        # 毎朝の全件再生成で、中身の変わっていないファイルまで書き直さない。
        if not out_path.exists() or out_path.read_text(encoding="utf-8") != payload:
            out_path.write_text(payload, encoding="utf-8")
        generated.add(out_path.name)

    js = "window.REPORT_INDEX = " + json.dumps(index, ensure_ascii=False, indent=2) + ";\n"
    INDEX_FILE.write_text(js, encoding="utf-8")
    print(f"generated {INDEX_FILE} and {len(index)} files under {OUT_DIR}")

    # レポートをリネーム・削除すると、対応表から外れたJSONが取り残される。
    # 消すと元に戻せないので、ここでは知らせるだけにして自動削除はしない。
    orphans = sorted(p.name for p in OUT_DIR.glob("*.json") if p.name not in generated)
    if orphans:
        print("該当する report/*.md が無いファイル（削除していません）: " + ", ".join(orphans))


if __name__ == "__main__":
    main()
