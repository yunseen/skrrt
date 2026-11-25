// Scroll Tools: a reading progress bar and quick jumps to the top and the bottom of the page.
var showProgress = Skrrt.options.get('progress', true);
var side = Skrrt.options.get('side', 'right');

var bar = Skrrt.el('div', {
  style: { position: 'fixed', top: '0', left: '0', height: '3px', width: '0', background: '#0a84ff', zIndex: 2147483647, pointerEvents: 'none', display: showProgress ? 'block' : 'none' }
});

function roundButton(text, offset, handler) {
  var b = Skrrt.el('button', {
    text: text,
    onclick: handler,
    style: {
      position: 'fixed', bottom: offset + 'px', width: '42px', height: '42px', borderRadius: '21px',
      border: '1px solid rgba(255,255,255,.25)', background: 'rgba(20,20,24,.78)', color: '#fff',
      font: '700 18px -apple-system,sans-serif', zIndex: 2147483646, display: 'none'
    }
  });
  b.style[side === 'left' ? 'left' : 'right'] = '12px';
  return b;
}
var up = roundButton('↑', 150, function () { scrollTo({ top: 0, behavior: 'smooth' }); });
var down = roundButton('↓', 100, function () { scrollTo({ top: document.documentElement.scrollHeight, behavior: 'smooth' }); });

function update() {
  var max = document.documentElement.scrollHeight - innerHeight;
  var y = scrollY;
  bar.style.width = max > 0 ? Math.min(100, y / max * 100) + '%' : '0';
  var tall = max > innerHeight;
  up.style.display = tall && y > 500 ? 'block' : 'none';
  down.style.display = tall && y < max - 500 ? 'block' : 'none';
}

Skrrt.ready(function () {
  document.documentElement.appendChild(bar);
  document.documentElement.appendChild(up);
  document.documentElement.appendChild(down);
  update();
});
addEventListener('scroll', update, { passive: true });
addEventListener('resize', update);
