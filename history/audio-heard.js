(function (root, factory) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = factory();
  } else {
    root.AudioHeard = factory();
  }
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  const DEFAULT_STORAGE_KEY = 'ai_news.audio_heard_dates';

  function loadDates(storage, key) {
    if (!storage) return new Set();

    try {
      const parsed = JSON.parse(storage.getItem(key) || '[]');
      return new Set(Array.isArray(parsed) ? parsed.filter(date => typeof date === 'string') : []);
    } catch (e) {
      return new Set();
    }
  }

  function createAudioHeardStore(storage, key = DEFAULT_STORAGE_KEY) {
    const heardDates = loadDates(storage, key);

    function persist() {
      if (!storage) return;
      try {
        storage.setItem(key, JSON.stringify([...heardDates].sort()));
      } catch (e) {
        // Private browsingなどで保存できない場合も、現在のページ内状態は維持する。
      }
    }

    return {
      has(date) {
        return heardDates.has(date);
      },
      set(date, heard) {
        if (heard) heardDates.add(date);
        else heardDates.delete(date);
        persist();
      },
    };
  }

  return { createAudioHeardStore };
}));
