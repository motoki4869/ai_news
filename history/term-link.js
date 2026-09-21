/* 記事本文中の用語を用語集ページへのリンクに変換する。
 * glossary-data.js (window.GLOSSARY) を先に読み込んだページでのみ動作する。
 * 「正式名称」列ではなく、用語集の「用語」列に載っている用語と、その括弧内・
 * スラッシュ区切りの別名を対象にする。用語集に登録された内容と本文の表記を
 * 一致させるため、英字の略語だけでなく日本語の用語もリンク化する。
 */
(function () {
  const GLOSSARY = window.GLOSSARY || [];
  if (!GLOSSARY.length) return;

  function decodeHtmlEntities(text) {
    return text
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, "'");
  }

  function addAlias(aliases, known, raw) {
    const alias = raw.trim().replace(/\s+等$/, '');
    if (!alias || alias === '等' || known.has(alias)) return;
    known.add(alias);
    aliases.push(alias);
  }

  function collectAliases(termHtml) {
    const term = decodeHtmlEntities(termHtml.replace(/<[^>]+>/g, ''));
    const aliases = [];
    const known = new Set();

    function addParts(value) {
      addAlias(aliases, known, value);
      value.split(/\s+\/\s+|\s+→\s+/).forEach(part => addAlias(aliases, known, part));
    }

    addParts(term);
    const base = term.replace(/[（(][^）)]*[）)]/g, '').trim();
    if (base !== term) addParts(base);

    const parentheses = /[（(]([^）)]*)[）)]/g;
    let match;
    while ((match = parentheses.exec(term))) addParts(match[1]);
    return aliases;
  }

  const tokens = [];
  const known = new Set();
  GLOSSARY.forEach(sec => {
    sec.entries.forEach(entry => {
      collectAliases(entry.term).forEach(alias => {
        if (!known.has(alias)) {
          known.add(alias);
          tokens.push(alias);
        }
      });
    });
  });
  if (!tokens.length) return;

  // 長いトークンを先に判定する（例: "V4-Flash" が "V4" として途中一致しないように）。
  // ASCIIだけの用語には英数字境界を付け、一般語の一部だけをリンク化しない。
  tokens.sort((a, b) => b.length - a.length);
  const escaped = tokens.map(t => t.replace(/[-.*+?^${}()|[\]\\]/g, '\\$&'));
  const ascii = [];
  const other = [];
  tokens.forEach((token, index) => {
    if (/^[A-Za-z0-9][A-Za-z0-9 ._+/#-]*$/.test(token)) ascii.push(escaped[index]);
    else other.push(escaped[index]);
  });
  const alternatives = [];
  if (ascii.length) alternatives.push('\\b(?:' + ascii.join('|') + ')\\b');
  if (other.length) alternatives.push('(?:' + other.join('|') + ')');
  const pattern = new RegExp(alternatives.join('|'), 'g');

  function linkifyElement(el) {
    walk(el);
  }

  function linkifyTextNode(node) {
    const text = node.textContent;
    pattern.lastIndex = 0;
    let cursor = 0;
    let match;
    const frag = document.createDocumentFragment();
    let found = false;

    while ((match = pattern.exec(text))) {
      found = true;
      if (match.index > cursor) {
        frag.appendChild(document.createTextNode(text.slice(cursor, match.index)));
      }
      const term = match[0];
      const a = document.createElement('a');
      a.className = 'gloss-link';
      a.href = 'glossary.html?q=' + encodeURIComponent(term);
      a.textContent = term;
      // news.html / archive.html ではカード全体がタップで全文表示モーダルを開く
      // クリックハンドラを持つため、リンクのクリックがそこへ伝播しないようにする
      a.addEventListener('click', e => e.stopPropagation());
      frag.appendChild(a);
      cursor = match.index + term.length;
    }
    if (!found) return;
    if (cursor < text.length) frag.appendChild(document.createTextNode(text.slice(cursor)));
    node.replaceWith(frag);
  }

  function walk(node) {
    const children = Array.from(node.childNodes);
    for (const child of children) {
      if (child.nodeType === Node.ELEMENT_NODE) {
        if (child.tagName === 'A') continue;
        walk(child);
        continue;
      }
      if (child.nodeType !== Node.TEXT_NODE) continue;
      linkifyTextNode(child);
    }
  }

  // selector省略時はニュースカードの見出し下テキストが対象。レポート全文モーダルなど
  // 別の範囲に使う場合は呼び出し側でselectorを指定する（report-modal.js参照）。
  window.linkifyGlossaryTerms = function (root, selector) {
    (root || document).querySelectorAll(selector || '.news-card p, .news-card .point-list li').forEach(el => {
      if (el.dataset.glossLinked) return;
      el.dataset.glossLinked = '1';
      linkifyElement(el);
    });
  };
})();
