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

  function openModal(reportNames) {
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

  function closeModal() {
    modal.setAttribute('hidden', '');
    document.body.style.overflow = '';
  }

  closeBtn.addEventListener('click', closeModal);
  backdrop.addEventListener('click', closeModal);
  document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && !modal.hasAttribute('hidden')) closeModal();
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
