/* 記事本文中の主要な用語（英字の略語・製品名）を用語集ページへのリンクに変換する。
 * glossary-data.js (window.GLOSSARY) を先に読み込んだページでのみ動作する。
 * 一般的な英単語まで誤ってリンク化しないよう、対象は用語集の「用語」列に載っている
 * ASCII の略語・製品名（例: MCP, RAG, MoE）だけに絞ってある。日本語の用語名や、
 * 「正式名称」列に載っている長い英語表記（Model Context Protocol 等）は対象外。
 */
(function () {
  const GLOSSARY = window.GLOSSARY || [];
  if (!GLOSSARY.length) return;

  const TOKEN_RE = /^[A-Za-z][A-Za-z0-9-]{2,10}$/;
  const tokens = [];
  const known = new Set();
  GLOSSARY.forEach(sec => {
    sec.entries.forEach(entry => {
      entry.term.replace(/<\/?strong>/g, '').split(' / ').forEach(raw => {
        const tok = raw.trim();
        if (TOKEN_RE.test(tok) && !known.has(tok)) {
          known.add(tok);
          tokens.push(tok);
        }
      });
    });
  });
  if (!tokens.length) return;

  // 長いトークンを先に判定する（例: "V4-Flash" が "V4" として途中一致しないように）
  tokens.sort((a, b) => b.length - a.length);
  const escaped = tokens.map(t => t.replace(/[-.*+?^${}()|[\]\\]/g, '\\$&'));
  const pattern = new RegExp('\\b(' + escaped.join('|') + ')\\b');

  function linkifyElement(el) {
    const state = { done: false };
    walk(el, state);
  }

  function walk(node, state) {
    const children = Array.from(node.childNodes);
    for (const child of children) {
      if (state.done) return;
      if (child.nodeType === Node.ELEMENT_NODE) {
        if (child.tagName === 'A') continue;
        walk(child, state);
        continue;
      }
      if (child.nodeType !== Node.TEXT_NODE) continue;
      const m = pattern.exec(child.textContent);
      if (!m) continue;
      const term = m[1];
      const idx = m.index;
      const before = child.textContent.slice(0, idx);
      const after = child.textContent.slice(idx + term.length);
      const frag = document.createDocumentFragment();
      if (before) frag.appendChild(document.createTextNode(before));
      const a = document.createElement('a');
      a.className = 'gloss-link';
      a.href = 'glossary.html?q=' + encodeURIComponent(term);
      a.textContent = term;
      // news.html / archive.html ではカード全体がタップで全文表示モーダルを開く
      // クリックハンドラを持つため、リンクのクリックがそこへ伝播しないようにする
      a.addEventListener('click', e => e.stopPropagation());
      frag.appendChild(a);
      if (after) frag.appendChild(document.createTextNode(after));
      child.replaceWith(frag);
      state.done = true;
    }
  }

  // 1カードにつき最初に見つかった1語だけをリンク化する（複数語が光ると読みにくいため）
  window.linkifyGlossaryTerms = function (root) {
    (root || document).querySelectorAll('.news-card p, .news-card .point-list li').forEach(el => {
      if (el.dataset.glossLinked) return;
      el.dataset.glossLinked = '1';
      linkifyElement(el);
    });
  };
})();
