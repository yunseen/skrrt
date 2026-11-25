// Video Speed Controller: a small floating control for the playback speed of any video.
// Idea and behavior follow the open source "Video Speed Controller" extension.
var defaultSpeed = Number(Skrrt.options.get('defaultSpeed', 1));
var step = Number(Skrrt.options.get('step', 0.25));
var remember = Skrrt.options.get('remember', true);
var showControl = Skrrt.options.get('control', true);

var speed = remember ? Number(Skrrt.storage.get('speed', defaultSpeed)) : defaultSpeed;

function clamp(v) { return Math.min(4, Math.max(0.25, Math.round(v * 100) / 100)); }
function apply() {
  document.querySelectorAll('video, audio').forEach(function (m) {
    if (Math.abs(m.playbackRate - speed) > 0.001) m.playbackRate = speed;
  });
  label.textContent = speed.toFixed(2).replace(/0+$/, '').replace(/\.$/, '') + '×';
}
function set(value) {
  speed = clamp(value);
  if (remember) Skrrt.storage.set('speed', speed);
  apply();
}

var button = function (text, onclick) {
  return Skrrt.el('button', {
    text: text,
    style: { all: 'unset', cursor: 'pointer', padding: '8px 12px', font: '700 16px -apple-system,sans-serif', color: '#fff' },
    onclick: onclick
  });
};
var label = Skrrt.el('span', {
  style: { font: '700 14px -apple-system,sans-serif', color: '#fff', minWidth: '44px', textAlign: 'center' },
  onclick: function () { set(1); }
});
var bar = Skrrt.el('div', {
  style: {
    position: 'fixed', left: '10px', bottom: '96px', zIndex: 2147483647, display: 'none',
    alignItems: 'center', borderRadius: '999px', background: 'rgba(20,20,24,.78)',
    border: '1px solid rgba(255,255,255,.22)', userSelect: 'none', webkitUserSelect: 'none'
  }
}, button('−', function () { set(speed - step); }), label, button('+', function () { set(speed + step); }));

Skrrt.ready(function () { document.documentElement.appendChild(bar); });
Skrrt.every(700, function () {
  var has = document.querySelector('video');
  bar.style.display = showControl && has ? 'flex' : 'none';
  if (has) apply();
});
