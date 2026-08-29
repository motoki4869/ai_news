(function (root, factory) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = factory();
  } else {
    root.DailyNavigation = factory();
  }
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  const DEFAULT_SWIPE_THRESHOLD = 48;

  function getAdjacentDate(dates, currentDate, direction) {
    const currentIndex = dates.indexOf(currentDate);
    if (currentIndex === -1) return null;
    if (direction !== 'previous' && direction !== 'next') return null;

    const offset = direction === 'next' ? 1 : -1;
    return dates[currentIndex + offset] || null;
  }

  function getSwipeDirection(startX, startY, endX, endY, threshold = DEFAULT_SWIPE_THRESHOLD) {
    const deltaX = endX - startX;
    const deltaY = endY - startY;

    if (Math.abs(deltaX) < threshold || Math.abs(deltaX) <= Math.abs(deltaY)) return null;
    return deltaX > 0 ? 'next' : 'previous';
  }

  return { getAdjacentDate, getSwipeDirection };
}));
