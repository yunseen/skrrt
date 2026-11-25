// Picture in Picture: a floating button that moves the current video into a small floating window.
var side = Skrrt.options.get('side', 'right');

var button = Skrrt.el('button', {
  'aria-label': 'Picture in Picture',
  style: {
    position: 'fixed', bottom: '150px', zIndex: 2147483647, display: 'none',
    width: '44px', height: '44px', borderRadius: '22px', border: '1px solid rgba(255,255,255,.25)',
    background: 'rgba(20,20,24,.78)', color: '#fff', font: '600 18px -apple-system,sans-serif'
  },
  text: '⧉',
  onclick: function () {
    var video = bestVideo();
    if (!video) return;
    try {
      if (video.webkitPresentationMode === 'picture-in-picture') video.webkitSetPresentationMode('inline');
      else video.webkitSetPresentationMode('picture-in-picture');
    } catch (e) { Skrrt.toast(Skrrt.lang === 'ru' ? 'Не получилось' : 'Not available'); }
  }
});
button.style[side === 'left' ? 'left' : 'right'] = '12px';

function bestVideo() {
  var list = Array.prototype.slice.call(document.querySelectorAll('video'));
  list = list.filter(function (v) { return v.readyState > 0 && v.webkitSupportsPresentationMode && v.webkitSupportsPresentationMode('picture-in-picture'); });
  list.sort(function (a, b) { return (b.videoWidth * b.videoHeight) - (a.videoWidth * a.videoHeight); });
  return list[0] || null;
}

Skrrt.ready(function () { document.documentElement.appendChild(button); });
Skrrt.every(900, function () {
  var v = bestVideo();
  button.style.display = v && (v.duration > 20 || !isFinite(v.duration)) ? 'block' : 'none';
});
