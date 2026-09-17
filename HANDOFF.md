# HANDOFF (2026-09-17 21:19, from Claude Code)

## やっていたこと
AI_newsサイト（`history/` 配下の静的サイト、本番 https://ai-news-sandy-seven.vercel.app）の
「0ベースの見直し」で洗い出した改善案（優先度1〜9、`docs/site-improvement-backlog.md`）を、
ユーザーと1項目ずつ相談しながら優先度順に実装しています。
途中でCodexフォールバックが定時実行から起動できない不具合が見つかり、そちらも対応しました。

## 完了済み
- 優先度9-b: `daily.html` の音声プレイヤーを自作UIに置き換え（`00352fd`）。
  9-a（明朝化）と9-c（index年表の再設計）はユーザー判断で**やらない**。
- Codexフォールバックの起動不具合を ai_news / investment 両方で修正（ai_news `624ad55`、investment `fe1df1a`）。
- iPad・PC幅（900px以上）で音声パネルを2列グリッドに組み直し、速度ボタンと「視聴済み」を
  プレイヤーの真上（右上）へ移動（`d13f8a0`）。狭い画面の並びは変更なし。
- 両リポジトリとも作業ツリーはクリーン、push済み。

## 次の一手
- ユーザーの回答待ち: `test/test_daily_navigation.js` の
  「`.day-head h2` に `scroll-margin-top: 64px`」を期待する失敗テストを直すか。
  実装は `calc(var(--nav-h) + 18px)` が正しい（スマホでロゴが2行になる対策）ので、
  直すならテスト側の期待値を変える。**この1件は本セッションの変更とは無関係の既存の失敗**。
- 明日6:30の日次バッチで上限に当たった場合、`logs/daily_news.log` を確認する。
  フォールバックの**起動経路は直したが、上限の検出はまだ実地検証できていない**（下記）。
- 未着手で保留のバックログ: 優先度4（OGP / canonical / sitemap）。
  やらないと決まったもの: 優先度2 / 6B / 7 / 9-a / 9-c。見送り: 優先度8（配色整理＋背景canvasフェード）。

## 注意点・ハマりどころ
- **ユーザーとの進め方**: 各項目を実装する前に「なぜ必要か」を初学者向けに解説し、
  やるかどうかの判断を仰ぐ。勝手に先に進めない。コミットしたら必ずpushまで行う。
- **上限検出は未検証**: `is_claude_limit_reached()` は
  `You've hit your (weekly|session) limit` の文字列一致。実際のClaude CLIの文言が違うと
  そもそもフォールバックに入らない。実際に上限に当たるまで確認できない。
- **launchdのPATHは `/usr/bin:/bin:/usr/sbin:/sbin` しかない**。`.zshrc` は読まれず、
  ロケールも渡らない（Cロケール）。今回の不具合も、`codex` が見つからない→
  解決しても `codex` は `#!/usr/bin/env node` のNodeスクリプトなので `node` も見つからない、
  という2段構えだった。検証は必ず `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin HOME=$HOME` で行う。
- `scripts/lib/codex_fallback.sh` は ai_news と investment に**意図的に同一内容を複製配置**している。
  片方を直したらもう片方も直す（現在の差分は `send_line_broadcast` の `curl` オプションのみ）。
- **ブラウザ確認は `cmux browser`**（claude-in-chrome拡張ではない）。サーフェスは `--surface surface:5`。
  ビューポートのリサイズ機能が無いため、**localhost の同一オリジンで iframe を作り、
  その幅を変えて `getBoundingClientRect()` を測る**方法を使った（`documentElement.style.zoom` では
  メディアクエリが切り替わらない）。ローカルは `history/` で `python3 -m http.server 8801`。
- `node --test test/` はディレクトリ指定だと `__pycache__` を拾って落ちる。`node --test test/*.js` を使う。
- 音声パネルのCSSは、狭い画面が `.audio-copy` のグリッド、900px以上が `.audio-inner` のグリッドで、
  `.audio-copy { display: contents }` により升目の名前（kicker/title/desc/actions）を共用している。
  片方だけ触ると崩れるので、変更したら両方の幅で実測すること。

## 関連ファイル
- `docs/site-improvement-backlog.md` — 優先度1〜9の一覧と、各項目の判断・実測データ
- `docs/CHANGELOG.md` — 見た目・挙動が変わった変更の記録（1依頼＝1エントリ、新しい日付が上）
- `history/daily.html` — 日次ログページ。音声プレイヤーのHTML/CSS/JSはすべてこの中
- `history/audio-player.js` — 自作プレイヤーの計算部分（`formatTime` / `bufferedEnd` / `percentOf`）
- `scripts/lib/codex_fallback.sh` — Claude上限時のCodexフォールバック共通ヘルパー（investmentにも複製）
- `scripts/daily_news.sh` — 6:30のlaunchdジョブ本体（`com.motoki.ainews.daily`）
