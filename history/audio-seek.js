(function (root, factory) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = factory();
  } else {
    root.AudioSeek = factory();
  }
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  function seekAudio(audio, seconds) {
    if (!audio || !Number.isFinite(audio.currentTime) || !Number.isFinite(seconds)) return false;

    const duration = Number.isFinite(audio.duration) ? Math.max(0, audio.duration) : null;
    const target = Math.max(0, audio.currentTime + seconds);
    audio.currentTime = duration === null ? target : Math.min(target, duration);
    return true;
  }

  function setPlaybackRate(audio, rate) {
    const value = Number(rate);
    if (!audio || (value !== 1 && value !== 1.5 && value !== 2)) return false;

    audio.playbackRate = value;
    return true;
  }

  return { seekAudio, setPlaybackRate };
}));
