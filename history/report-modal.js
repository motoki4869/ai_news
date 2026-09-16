/* news-card タップ → data-report の元レポート全文をモーダル表示
   history/reports-data.js の window.REPORTS を参照する。
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
        <button class="report-modal-close" aria-label="閉じる">×</button>
      </div>
      <div class="report-modal-body"></div>
    </div>
  `;
  document.body.appendChild(modal);

  const body = modal.querySelector('.report-modal-body');
  const closeBtn = modal.querySelector('.report-modal-close');
  const backdrop = modal.querySelector('.report-modal-backdrop');

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

  function isOpen() {
    return !modal.hasAttribute('hidden');
  }

  function renderModal(reportNames) {
    const reports = (window.REPORTS || {});
    const sections = reportNames.map(name => {
      const html = reports[name];
      if (!html) {
        return `<section class="rpt-section"><h2>${name}</h2><p class="rpt-missing">この記事の全文データは未登録です。</p></section>`;
      }
      return `<section class="rpt-section">${html}</section>`;
    });
    body.innerHTML = sections.join('<hr class="rpt-divider">');
    body.querySelectorAll('table.rpt-table').forEach(table => {
      const wrap = document.createElement('div');
      wrap.className = 'rpt-table-wrap';
      table.parentNode.insertBefore(wrap, table);
      wrap.appendChild(table);
    });
    if (window.renderMathInElement) {
      window.renderMathInElement(body, {
        delimiters: [
          { left: '$$', right: '$$', display: true },
          { left: '$', right: '$', display: false }
        ],
        throwOnError: false
      });
    }
    modal.removeAttribute('hidden');
    document.body.style.overflow = 'hidden';
    body.scrollTop = 0;
  }

  function openModal(reportNames) {
    // 開いている上から別のカードを開く経路ができても、履歴を二重に積まない。
    if (isOpen()) {
      renderModal(reportNames);
      return;
    }
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
    modal.setAttribute('hidden', '');
    document.body.style.overflow = '';
    openedViaHistory = false;
  }

  // ユーザーが「閉じる」意思を示したとき。閉じる処理そのものは popstate に任せる。
  function requestClose() {
    if (!isOpen()) return;
    if (openedViaHistory) history.back();
    else hideModal();
  }

  closeBtn.addEventListener('click', requestClose);
  backdrop.addEventListener('click', requestClose);
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && isOpen()) requestClose();
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
