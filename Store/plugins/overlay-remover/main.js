// Overlay Remover: removes full-screen "subscribe", "sign in" and newsletter walls and unlocks scrolling.
var mode = Skrrt.options.get('mode', 'auto');
var KEEP = /cookie|consent|gdpr|player|video|lightbox|gallery|viewer|chat|menu|nav|search|dialog-confirm/i;

function unlock() {
  [document.documentElement, document.body].forEach(function (e) {
    if (!e) return;
    if (getComputedStyle(e).overflow === 'hidden') e.style.setProperty('overflow', 'auto', 'important');
    e.style.setProperty('position', e.style.position === 'fixed' ? 'static' : e.style.position, 'important');
  });
}

function sweep() {
  var vw = innerWidth, vh = innerHeight, removed = false;
  document.querySelectorAll('body *').forEach(function (n) {
    var cs = getComputedStyle(n);
    if (cs.position !== 'fixed' && cs.position !== 'sticky') return;
    if ((parseInt(cs.zIndex, 10) || 0) < 100) return;
    if (KEEP.test(n.id + ' ' + n.className)) return;
    var r = n.getBoundingClientRect();
    if (r.width >= vw * 0.6 && r.height >= vh * 0.5) {
      n.remove();
      removed = true;
    }
  });
  if (removed) unlock();
}

Skrrt.ready(function () {
  sweep();
  var runs = 0;
  var id = Skrrt.every(1200, function () {
    sweep();
    if (mode === 'auto' && ++runs > 8) clearInterval(id);
  });
});
