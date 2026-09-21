# Claude Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Codeの再レビューで見つかった日次・週次ニュース更新の競合、再実行通知、入力検証、テスト隔離の問題を解消する。

**Architecture:** 日次処理はプロセス所有ロック、週次エージェント処理は期限付きリースロックを使い分ける。日次スクリプトは成功判定・LINE通知・音声生成を独立させ、ニュース本文が当日分までcommit済みならSummary失敗時も音声を再試行できるようにする。

**Tech Stack:** Bash、Python 3、Node.js built-in test runner、Markdown。

**Spec:** Claude Codeレビュー結果（2026-09-21、High 3件・Medium 6件・Low 2件）。

## Global Constraints

- 既存のClaude版・Codex版日次プロンプトは検索ツール名以外の手順を一致させる。
- 用語集の生成失敗時は既存の生成物を保持する。
- 日次・週次更新は同一リポジトリの原本・生成物・Git indexを同時に変更しない。
- 変更後は関連テスト、全Nodeテスト、全Pythonテスト、shell構文検査、差分検査、Claude再レビューを実行する。

---

### Task 1: 回帰テストの追加

**Files:**
- Modify: `test/test_daily_news.sh`
- Modify: `test/test_daily_prompt_glossary.js`
- Modify: `test/test_generate_glossary_data.py`
- Modify: `test/test_news_update_lock.sh`

- [x] 用語集の2列目空欄を許可し、1列目・3列目空欄を拒否するテストへ変更する。
- [x] 日次スクリプトを一時リポジトリで実行し、LINE通知の再実行、SUMMARY旧形式、commit済み当日分の音声再試行を検証する。
- [x] ロックの所有者確認、leaseの期限、stale回収競合、非所有者releaseを検証する。
- [x] プロンプトの冪等再実行、SUMMARY形式、空欄方針を検証する。
- [x] 各テストを実装前に実行し、想定どおり失敗することを確認する。

### Task 2: ロックの所有権・lease・stale回収の修正

**Files:**
- Modify: `scripts/lib/news_update_lock.sh`
- Modify: `.agents/skills/sync-news-html/SKILL.md`

- [x] プロセス開始情報と一意トークンを保存し、所有者以外のreleaseを無効化する。
- [x] 週次向けlease取得・更新・明示解放を追加する。
- [x] stale回収はlock directoryの原子的renameで行い、PID再利用をプロセス開始情報と期限で防ぐ。
- [x] 失敗時・終了時に安全に後始末できるよう日次スクリプトのtrapを調整する。

### Task 3: 日次実行の再実行・通知・音声処理の修正

**Files:**
- Modify: `scripts/daily_news.sh`

- [x] REPO_DIRとスクリプト資材の解決を分離し、テストが一時リポジトリを使えるようにする。
- [x] 成功時はmtime差分ではなく日付単位の通知claimでLINEを一度だけ送る。
- [x] 当日分がHEADにcommit済みなら、SUMMARY失敗時も音声処理だけは再試行する。
- [x] 失敗Summaryの原因を失敗通知へ引き継ぐ。

### Task 4: プロンプト・用語集検証・生成物モードの修正

**Files:**
- Modify: `scripts/daily_news_prompt.txt`
- Modify: `scripts/daily_news_prompt.codex.txt`
- Modify: `scripts/generate_glossary_data.py`

- [x] 同日再実行でもLINE通知文を再生成し、変更なしcommitを正常系として扱う。
- [x] 警告経路をSUMMARY: ERROR:へ統一する。
- [x] 正式名称・読みの空欄方針を既存ドキュメントと一致させる。
- [x] 原子的置換前に既存生成物のパーミッションを維持する。

### Task 5: 検証・記録・再レビュー

**Files:**
- Modify: `docs/CHANGELOG.md`

- [x] 関連テスト、全テスト、shell構文検査、差分検査を実行する。
- [x] CHANGELOGに理由・対象・commitを追記する。
- [ ] commit・push後、Claude Codeへ最新commitの再レビューを依頼する。
