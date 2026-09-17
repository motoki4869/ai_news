/* 自作音声プレイヤーの計算部分。DOM操作は daily.html 側に置き、ここには
   「秒数をどう表示するか」「バーを何%まで伸ばすか」だけを置く（テストしやすくするため）。 */
(function (root, factory) {
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = factory();
  } else {
    root.AudioPlayerUI = factory();
  }
}(typeof globalThis !== 'undefined' ? globalThis : this, function () {
  /* 秒数を「M:SS」（1時間以上なら「H:MM:SS」）にする。
     メタデータ読み込み前の duration は NaN や Infinity になるので、その場合は伸び縮み
     しない固定幅のプレースホルダを返す（表示が出たり消えたりして幅が動かないように）。 */
  function formatTime(seconds) {
    if (!Number.isFinite(seconds) || seconds < 0) return '--:--';

    const total = Math.floor(seconds);
    const hours = Math.floor(total / 3600);
    const minutes = Math.floor((total % 3600) / 60);
    const rest = total % 60;
    const mm = hours > 0 ? String(minutes).padStart(2, '0') : String(minutes);

    return (hours > 0 ? hours + ':' : '') + mm + ':' + String(rest).padStart(2, '0');
  }

  /* 読み込み済みの範囲の終端（秒）。
     シークで飛ぶとダウンロード済みの範囲が複数に分かれるため、いま再生している位置を
     含む範囲だけを見る。どの範囲にも入っていない（シーク直後など）なら0を返す。 */
  function bufferedEnd(audio) {
    if (!audio || !audio.buffered || audio.buffered.length === 0) return 0;

    const current = Number.isFinite(audio.currentTime) ? audio.currentTime : 0;
    for (let i = 0; i < audio.buffered.length; i += 1) {
      if (audio.buffered.start(i) <= current && current <= audio.buffered.end(i)) {
        return audio.buffered.end(i);
      }
    }
    return 0;
  }

  /* バーの幅に使う0〜100の値。長さが未確定（0やNaN）のうちは0%にしておく。 */
  function percentOf(value, total) {
    if (!Number.isFinite(value) || !Number.isFinite(total) || total <= 0) return 0;
    return Math.min(100, Math.max(0, (value / total) * 100));
  }

  return { formatTime, bufferedEnd, percentOf };
}));
