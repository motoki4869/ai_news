/* news-card タップ → data-report の元レポート全文をモーダル表示
   全文は history/reports/<ID>.json に1本ずつ置かれている。日本語のレポート名から
   ID を引く対応表が history/reports-index.js の window.REPORT_INDEX。
   news.html / archive.html 共通で読み込む。 */
(function () {
  const modal = document.createElement('div');
  modal.id = 'report-modal';
  modal.className = 'report-modal';
  modal.setAttribute('hidden', '');
  modal.innerHTML = `
    <div class="report-modal-backdrop"></div>
    <div class="report-modal-panel" role="dialog" aria-modal="true">
      <div class="report-modal-header">
        <button class="report-modal-toc-toggle" type="button" aria-expanded="false" aria-controls="report-modal-toc">
          <span class="report-modal-toc-icon" aria-hidden="true"><i></i><i></i><i></i></span>
          <span>章一覧</span>
        </button>
        <button class="report-modal-close" aria-label="閉じる">×</button>
      </div>
      <div class="report-modal-body"></div>
    </div>
  `;
  document.body.appendChild(modal);

  const body = modal.querySelector('.report-modal-body');
  const panel = modal.querySelector('.report-modal-panel');
  const tocToggle = modal.querySelector('.report-modal-toc-toggle');
  const closeBtn = modal.querySelector('.report-modal-close');
  const backdrop = modal.querySelector('.report-modal-backdrop');

  /* 全文データの取り方

     以前は全レポートのHTML（約800KB）を1つの reports-data.js として同期読み込みして
     いた。ページを開いただけで全部落ちてくるのに、実際に読まれるのはタップした1本
     だけなので、初回表示の転送量をそのぶん丸ごと捨てていた。今はタップされた分だけを
     fetch し、一度取ったものはこのMapに残して2回目以降は通信しない。

     Mapの値はHTML文字列ではなくPromise。同じカードを連打されても fetch は1回で済む。 */
  const cache = new Map();

  function loadReport(name) {
    if (cache.has(name)) return cache.get(name);
    const fileId = (window.REPORT_INDEX || {})[name];
    // 対応表に無い＝まだ全文が用意されていない。通信せずに「未登録」を返す。
    const promise = fileId
      ? fetch('reports/' + fileId + '.json')
          .then(res => {
            if (!res.ok) throw new Error('HTTP ' + res.status);
            return res.json();
          })
          .then(data => data.html)
      : Promise.resolve(null);
    // 失敗したものは覚えない。開き直したときにもう一度取りに行けるようにする。
    promise.catch(() => cache.delete(name));
    cache.set(name, promise);
    return promise;
  }

  /* 最新トレンドでは、ページを開いた時点で表示対象のレポートを先読みする。
     一方、過去ログでは先読みせず、タップされたレポートだけを取得する。
     最新トレンドか過去ログかは data-page="news" で判定する。
     先読み対象は各カードの data-report から収集するため、レポートの追加や循環のたびに
     固定リストを更新する必要はない。

     loadReport() と同じ Promise をキャッシュするため、先読み中にタップされても
     fetch が重複することはない。先読み完了後は、通信を待たずにレポートを表示できる。 */
  function preloadNewsReports() {
    if (document.body.dataset.page !== 'news') return;
    const names = new Set();
    document.querySelectorAll('.news-card[data-report]').forEach(card => {
      card.dataset.report.split('/').map(s => s.trim()).filter(Boolean).forEach(name => names.add(name));
    });
    names.forEach(name => loadReport(name));
  }

  // このスクリプトはカードの後ろで読み込まれるため、DOMContentLoadedを待たずに始める。
  preloadNewsReports();

  /* 履歴の扱い（ここを崩すと戻るボタンが壊れる）

     モーダルの開閉はDOM属性の切り替えでしかないので、何もしないとブラウザの履歴には
     一切現れない。するとスマホのスワイプバックは「モーダルを閉じる」ではなく
     「news.htmlに来る前のページへ戻る」になり、読んでいる途中でサイトから出てしまう。
     そこで開くときに pushState で履歴を1段積み、戻る操作を popstate で受けて閉じる。

       ×ボタン/背景/Esc : requestClose() → history.back() → popstate → hideModal()
       スワイプバック    : ブラウザが履歴を戻す        → popstate → hideModal()

     履歴を戻す責任は requestClose() だけが持ち、hideModal() は必ずその後に呼ばれるので
     履歴に触らない。hideModal() を requestClose() を通さず直接呼ぶ経路を作ってはいけない。
     閉じても位置が modal のまま下がらず、次に開いたときの pushState が上書きではなく
     純粋な追加になるため、開くたびに履歴が1段ずつ伸び続ける。 */
  let openedViaHistory = false;

  /* いま表示しようとしている内容の世代番号。fetch の待ち時間中に別のカードを開かれたり
     モーダルを閉じられたりすると、古い方の結果が後から届いて画面を上書きしてしまう。
     届いた時点で自分が最新かどうかを確かめるために使う。 */
  let renderToken = 0;

  /* フォーカス管理
     開く前にフォーカスしていた要素（タップしたカード）を覚えておき、閉じたら戻す。
     開いている間は Tab がモーダルの外（背後のカード列）へ抜けないよう、
     モーダル内の focusable 要素だけを巡回させる（フォーカストラップ）。 */
  let returnFocusEl = null;
  let tocPanel = null;
  let tocOpen = false;

  function getFocusable() {
    return Array.from(
      modal.querySelectorAll('a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])')
    ).filter(el => el.offsetParent !== null);
  }

  function trapFocus(e) {
    const focusables = getFocusable();
    if (!focusables.length) { e.preventDefault(); return; }
    const first = focusables[0];
    const last = focusables[focusables.length - 1];
    const inside = modal.contains(document.activeElement);
    if (e.shiftKey) {
      if (!inside || document.activeElement === first) { e.preventDefault(); last.focus(); }
    } else {
      if (!inside || document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
  }

  function isOpen() {
    return !modal.hasAttribute('hidden');
  }

  function setTocOpen(open) {
    if (!tocPanel) return;
    tocOpen = open;
    tocPanel.hidden = !open;
    tocToggle.setAttribute('aria-expanded', String(open));
    tocToggle.classList.toggle('is-open', open);
    if (open) {
      const firstItem = tocPanel.querySelector('.report-modal-toc-sheet button');
      if (firstItem) firstItem.focus();
    } else if (isOpen()) {
      tocToggle.focus();
    }
  }

  function createReadingGuide(section, reportIndex) {
    const paragraphs = Array.from(section.querySelectorAll(':scope > p'));
    const headings = Array.from(section.querySelectorAll('h2, h3, h4'));
    const characterCount = section.textContent.replace(/\s+/g, '').length;
    const minutes = Math.max(1, Math.ceil(characterCount / 500));
    const guide = document.createElement('aside');
    guide.className = 'rpt-reading-guide';

    const meta = document.createElement('div');
    meta.className = 'rpt-reading-meta';
    meta.innerHTML = `
      <span class="rpt-guide-label">長いレポートの読み方</span>
      <span class="rpt-reading-time">読了目安 約${minutes}分</span>
    `;
    guide.appendChild(meta);

    if (paragraphs.length) {
      const summary = document.createElement('div');
      summary.className = 'rpt-summary';
      const summaryLabel = document.createElement('span');
      summaryLabel.className = 'rpt-summary-label';
      summaryLabel.textContent = '冒頭の3行要約';
      const summaryText = document.createElement('p');
      summaryText.textContent = paragraphs
        .slice(0, 3)
        .map(paragraph => paragraph.textContent.trim())
        .filter(Boolean)
        .join(' ');
      summary.append(summaryLabel, summaryText);
      guide.appendChild(summary);
    }

    // レポートの先頭にある h2 はタイトルなので、章目次からは除外する。
    const firstElement = section.firstElementChild;
    const tocHeadings = firstElement === headings[0] ? headings.slice(1) : headings;
    tocHeadings.forEach((heading, headingIndex) => {
      heading.id = `rpt-${reportIndex}-section-${headingIndex}`;
    });
    section.insertBefore(guide, section.firstChild);
    return tocHeadings;
  }

  function createTocPanel(entries) {
    if (tocPanel) tocPanel.remove();
    tocPanel = null;
    tocToggle.hidden = !entries.length;
    tocToggle.setAttribute('aria-expanded', 'false');
    tocToggle.classList.remove('is-open');
    tocOpen = false;
    if (!entries.length) return;

    tocPanel = document.createElement('nav');
    tocPanel.id = 'report-modal-toc';
    tocPanel.className = 'report-modal-toc';
    tocPanel.setAttribute('aria-label', 'レポートの章');
    tocPanel.setAttribute('hidden', '');
    tocPanel.innerHTML = `
      <div class="report-modal-toc-sheet">
        <div class="report-modal-toc-head">
          <span>章から読む</span>
          <button type="button" class="report-modal-toc-close" aria-label="章一覧を閉じる">×</button>
        </div>
        <ol class="report-modal-toc-list"></ol>
      </div>
    `;
    const sheet = tocPanel.querySelector('.report-modal-toc-sheet');
    const list = tocPanel.querySelector('.report-modal-toc-list');
    entries.forEach(({ heading }) => {
      const item = document.createElement('li');
      item.className = `rpt-toc-level-${heading.tagName.toLowerCase()}`;
      const link = document.createElement('button');
      link.type = 'button';
      link.textContent = heading.textContent;
      link.addEventListener('click', () => {
        setTocOpen(false);
        heading.scrollIntoView({ behavior: 'smooth', block: 'start' });
      });
      item.appendChild(link);
      list.appendChild(item);
    });
    tocPanel.addEventListener('click', event => {
      if (event.target === tocPanel) setTocOpen(false);
    });
    tocPanel.querySelector('.report-modal-toc-close').addEventListener('click', () => setTocOpen(false));
    sheet.addEventListener('click', event => event.stopPropagation());
    panel.appendChild(tocPanel);
  }

  function paint(results) {
    const sections = results.map(result => {
      if (result.html) {
        return `<section class="rpt-section">${result.html}</section>`;
      }
      const message = result.failed
        ? '全文を読み込めませんでした。通信環境を確認して、もう一度開いてください。'
        : 'この記事の全文データは未登録です。';
      return `<section class="rpt-section"><h2>${result.name}</h2><p class="rpt-missing">${message}</p></section>`;
    });
    body.innerHTML = sections.join('<hr class="rpt-divider">');
    const tocEntries = [];
    body.querySelectorAll('.rpt-section').forEach((section, reportIndex) => {
      if (!section.querySelector('.rpt-missing')) {
        createReadingGuide(section, reportIndex).forEach(heading => tocEntries.push({ heading }));
      }
    });
    createTocPanel(tocEntries);
    body.querySelectorAll('table.rpt-table').forEach(table => {
      const wrap = document.createElement('div');
      wrap.className = 'rpt-table-wrap';
      table.parentNode.insertBefore(wrap, table);
      wrap.appendChild(table);
    });
    // カード本文と同じ仕組みで、全文中の用語（MCP等）も用語集へリンクする。
    if (window.linkifyGlossaryTerms) {
      window.linkifyGlossaryTerms(body, '.rpt-section > p, .rpt-section > ul > li, .rpt-section td, .rpt-summary p');
    }
    if (window.renderMathInElement) {
      window.renderMathInElement(body, {
        delimiters: [
          { left: '$$', right: '$$', display: true },
          { left: '$', right: '$', display: false }
        ],
        throwOnError: false
      });
    }
    body.scrollTop = 0;
  }

  // 先に枠だけ開いてから中身を待つ。タップしても何も起きない時間を作らないため。
  function renderModal(reportNames) {
    const token = ++renderToken;
    setTocOpen(false);
    tocToggle.hidden = true;
    body.innerHTML = '<p class="rpt-loading">読み込み中…</p>';
    modal.removeAttribute('hidden');
    document.body.style.overflow = 'hidden';
    body.scrollTop = 0;
    closeBtn.focus();

    Promise.all(reportNames.map(name =>
      loadReport(name).then(
        html => ({ name: name, html: html }),
        () => ({ name: name, failed: true })
      )
    )).then(results => {
      if (token !== renderToken) return;  // 待っている間に閉じられた／別のカードが開かれた
      paint(results);
    });
  }

  function openModal(reportNames) {
    // 開いている上から別のカードを開く経路ができても、履歴を二重に積まない。
    if (isOpen()) {
      renderModal(reportNames);
      return;
    }
    returnFocusEl = document.activeElement;
    openedViaHistory = false;
    try {
      history.pushState({ reportModal: reportNames }, '', location.href);
      openedViaHistory = true;
    } catch (_) {
      // file:// など pushState が使えない環境。履歴が積まれていないので、
      // requestClose() は history.back() を呼ばずそのまま閉じる。
    }
    renderModal(reportNames);
  }

  // 見た目を閉じるだけ。履歴は呼び出し元（popstate）の時点で処理済み。
  function hideModal() {
    setTocOpen(false);
    modal.setAttribute('hidden', '');
    document.body.style.overflow = '';
    openedViaHistory = false;
    renderToken++;  // 読み込み中だったものが後から届いても描画させない
    if (returnFocusEl && document.contains(returnFocusEl)) returnFocusEl.focus();
    returnFocusEl = null;
  }

  // ユーザーが「閉じる」意思を示したとき。閉じる処理そのものは popstate に任せる。
  function requestClose() {
    if (!isOpen()) return;
    if (openedViaHistory) history.back();
    else hideModal();
  }

  tocToggle.addEventListener('click', () => setTocOpen(!tocOpen));
  closeBtn.addEventListener('click', requestClose);
  backdrop.addEventListener('click', requestClose);
  document.addEventListener('keydown', e => {
    if (!isOpen()) return;
    if (e.key === 'Escape') {
      if (tocOpen) { setTocOpen(false); return; }
      requestClose();
      return;
    }
    if (e.key === 'Tab') trapFocus(e);
  });

  window.addEventListener('popstate', e => {
    const names = e.state && e.state.reportModal;
    if (Array.isArray(names)) {
      // 「進む」でモーダルの履歴項目に入り直した場合。ブラウザが既に履歴を進めている
      // ので、ここで pushState してはいけない。開き直すだけにする。
      openedViaHistory = true;
      renderModal(names);
    } else if (isOpen()) {
      hideModal();
    }
  });

  function bindCards() {
    document.querySelectorAll('.news-card[data-report]').forEach(card => {
      if (card.dataset.modalBound) return;
      card.dataset.modalBound = '1';
      card.setAttribute('tabindex', '0');
      card.setAttribute('role', 'button');
      card.classList.add('tappable');
      const names = card.dataset.report.split('/').map(s => s.trim()).filter(Boolean);
      card.addEventListener('click', () => openModal(names));
      card.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); openModal(names); }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindCards);
  } else {
    bindCards();
  }
})();
