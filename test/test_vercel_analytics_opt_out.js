#!/usr/bin/env node

const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const analyticsPath = path.join(__dirname, '..', 'history', 'analytics.js');
const storageKey = 'ai_news_analytics_opt_out';

assert.ok(fs.existsSync(analyticsPath), 'Analyticsオプトアウト用スクリプトがありません');
const source = fs.readFileSync(analyticsPath, 'utf8');

function runAnalytics({ search = '', optedOut = false } = {}) {
  const storage = new Map();
  if (optedOut) storage.set(storageKey, '1');

  const appendedScripts = [];
  const context = {
    URLSearchParams,
    window: {
      location: { search },
      localStorage: {
        getItem: (key) => storage.get(key) ?? null,
        setItem: (key, value) => storage.set(key, value),
        removeItem: (key) => storage.delete(key),
      },
    },
    document: {
      createElement: () => ({}),
      head: { appendChild: (script) => appendedScripts.push(script) },
    },
  };

  vm.runInNewContext(source, context);
  return { storage, appendedScripts };
}

{
  const result = runAnalytics();
  assert.equal(result.appendedScripts.length, 1, '通常時はAnalyticsスクリプトを読み込む必要があります');
  assert.equal(result.appendedScripts[0].src, 'https://cdn.vercel-insights.com/v1/script.js');
}

{
  const result = runAnalytics({ search: '?analytics=off' });
  assert.equal(result.storage.get(storageKey), '1', 'analytics=offでこのブラウザの除外設定を保存する必要があります');
  assert.equal(result.appendedScripts.length, 0, '除外設定時はAnalyticsスクリプトを読み込んではいけません');
}

{
  const result = runAnalytics({ optedOut: true });
  assert.equal(result.appendedScripts.length, 0, '保存済みの除外設定があるブラウザでは計測してはいけません');
}

{
  const result = runAnalytics({ search: '?analytics=on', optedOut: true });
  assert.equal(result.storage.has(storageKey), false, 'analytics=onで除外設定を解除する必要があります');
  assert.equal(result.appendedScripts.length, 1, '除外設定解除後はAnalyticsスクリプトを読み込む必要があります');
}

console.log('Vercel Analyticsのブラウザ単位オプトアウトを確認しました。');
