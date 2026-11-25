// Return YouTube Dislike: shows likes and dislikes of the video you are watching.
// Data comes from returnyoutubedislikeapi.com (the dislike count is an estimate, as in the original extension).
var showViews = Skrrt.options.get('showViews', false);
var current = null;
var pill = null;

function videoId() {
  var u = new URL(location.href);
  if (u.pathname === '/watch') return u.searchParams.get('v');
  var m = u.pathname.match(/^\/shorts\/([\w-]{11})/);
  return m ? m[1] : null;
}

function format(n) {
  n = Number(n) || 0;
  if (n >= 1e9) return (n / 1e9).toFixed(1).replace(/\.0$/, '') + 'B';
  if (n >= 1e6) return (n / 1e6).toFixed(1).replace(/\.0$/, '') + 'M';
  if (n >= 1e3) return (n / 1e3).toFixed(1).replace(/\.0$/, '') + 'K';
  return String(n);
}

function ensurePill() {
  if (pill && pill.isConnected) return pill;
  pill = Skrrt.el('div', {
    style: {
      position: 'fixed', left: '12px', bottom: '96px', zIndex: 2147483646,
      padding: '7px 12px', borderRadius: '999px', pointerEvents: 'none',
      font: '600 13px -apple-system,sans-serif', color: '#fff',
      background: 'rgba(20,20,24,.78)', border: '1px solid rgba(255,255,255,.22)'
    }
  });
  document.documentElement.appendChild(pill);
  return pill;
}

function hide() {
  if (pill) { pill.remove(); pill = null; }
}

function load(id) {
  Skrrt.fetch('https://returnyoutubedislikeapi.com/votes?videoId=' + encodeURIComponent(id))
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (data) {
      if (!data || current !== id) return;
      var text = '👍 ' + format(data.likes) + '   👎 ' + format(data.dislikes);
      if (showViews && data.viewCount) text += '   👁 ' + format(data.viewCount);
      ensurePill().textContent = text;
    })
    .catch(function (e) { Skrrt.log('failed', e && e.message); });
}

Skrrt.every(700, function () {
  var id = videoId();
  if (id === current) return;
  current = id;
  hide();
  if (id) load(id);
});
