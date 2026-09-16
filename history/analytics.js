(function () {
  'use strict';

  const storageKey = 'ai_news_analytics_opt_out';
  const mode = new URLSearchParams(window.location.search).get('analytics');

  try {
    if (mode === 'off') {
      window.localStorage.setItem(storageKey, '1');
    } else if (mode === 'on') {
      window.localStorage.removeItem(storageKey);
    }
  } catch (error) {
    // localStorageが使えない環境では、通常どおり計測を試みる。
  }

  try {
    if (window.localStorage.getItem(storageKey) === '1') {
      return;
    }
  } catch (error) {
    // localStorageが使えない環境では、通常どおり計測を試みる。
  }

  window.va = window.va || function () {
    (window.vaq = window.vaq || []).push(arguments);
  };

  const script = document.createElement('script');
  script.defer = true;
  script.src = 'https://cdn.vercel-insights.com/v1/script.js';
  document.head.appendChild(script);
})();
