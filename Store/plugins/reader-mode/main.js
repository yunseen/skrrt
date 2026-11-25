// Reader Mode: a clean, distraction-free view of an article.
// The text container is found the way reader views usually do it: score the parents of long
// paragraphs and take the best one, then rebuild it from a small set of safe tags.
var fontSize = Number(Skrrt.options.get('fontSize', 19));
var theme = Skrrt.options.get('theme', 'auto');
var family = Skrrt.options.get('font', 'serif');

var ALLOWED = { H1: 1, H2: 1, H3: 1, H4: 1, P: 1, UL: 1, OL: 1, LI: 1, BLOCKQUOTE: 1, PRE: 1, CODE: 1, EM: 1, STRONG: 1, B: 1, I: 1, A: 1, IMG: 1, FIGURE: 1, FIGCAPTION: 1, BR: 1 };
var SKIP = /^(SCRIPT|STYLE|NOSCRIPT|NAV|ASIDE|FOOTER|FORM|BUTTON|IFRAME|SVG|CANVAS|VIDEO|AUDIO)$/;

function findArticle() {
  var preferred = document.querySelector('article');
  var scores = new Map();
  document.querySelectorAll('p').forEach(function (p) {
    var len = (p.innerText || '').trim().length;
    if (len < 60) return;
    var parent = p.parentElement;
    if (!parent) return;
    scores.set(parent, (scores.get(parent) || 0) + len);
    if (parent.parentElement) scores.set(parent.parentElement, (scores.get(parent.parentElement) || 0) + len * 0.4);
  });
  var best = null, bestScore = 0;
  scores.forEach(function (score, node) { if (score > bestScore) { best = node; bestScore = score; } });
  if (preferred && (!best || preferred.contains(best) || (preferred.innerText || '').length > bestScore * 0.6)) return { node: preferred, score: Math.max(bestScore, (preferred.innerText || '').length) };
  return best ? { node: best, score: bestScore } : null;
}

function clean(node, into) {
  Array.prototype.forEach.call(node.childNodes, function (child) {
    if (child.nodeType === 3) { into.appendChild(document.createTextNode(child.nodeValue)); return; }
    if (child.nodeType !== 1 || SKIP.test(child.tagName)) return;
    if (!ALLOWED[child.tagName]) { clean(child, into); return; }
    if (child.tagName === 'IMG') {
      var src = child.currentSrc || child.src;
      if (!src) return;
      var img = document.createElement('img');
      img.src = src;
      img.alt = child.alt || '';
      into.appendChild(img);
      return;
    }
    var copy = document.createElement(child.tagName);
    if (child.tagName === 'A' && child.href) copy.href = child.href;
    clean(child, copy);
    if (copy.childNodes.length || child.tagName === 'BR') into.appendChild(copy);
  });
}

var palette = {
  light: { bg: '#ffffff', fg: '#1d1d1f', muted: '#6e6e73' },
  sepia: { bg: '#f4ecd8', fg: '#433422', muted: '#7a6a55' },
  dark: { bg: '#121214', fg: '#e8e8ea', muted: '#9a9aa0' }
};
function colors() {
  var name = theme === 'auto' ? (Skrrt.isDark ? 'dark' : 'light') : theme;
  return palette[name] || palette.light;
}

var overlay = null;
var size = fontSize;

function render() {
  if (!overlay) return;
  var c = colors();
  overlay.style.background = c.bg;
  overlay.style.color = c.fg;
  overlay.querySelector('[data-body]').style.fontSize = size + 'px';
  overlay.querySelector('[data-body]').style.fontFamily = family === 'sans' ? '-apple-system, Helvetica, Arial, sans-serif' : 'Georgia, "Times New Roman", serif';
}

function open() {
  var found = findArticle();
  if (!found) { Skrrt.toast(Skrrt.lang === 'ru' ? 'Статья не найдена' : 'No article found'); return; }
  var body = Skrrt.el('div', { 'data-body': '1', style: { lineHeight: '1.65', margin: '0 auto', maxWidth: '680px', padding: '0 20px 120px' } });
  var titleEl = document.querySelector('h1');
  body.appendChild(Skrrt.el('h1', { text: (titleEl && titleEl.innerText.trim()) || document.title, style: { fontSize: '1.5em', lineHeight: '1.25', margin: '28px 0 8px' } }));
  body.appendChild(Skrrt.el('div', { text: location.hostname.replace(/^www\./, ''), style: { opacity: '.6', fontSize: '.8em', marginBottom: '20px' } }));
  clean(found.node, body);
  body.querySelectorAll('img').forEach(function (i) { i.style.maxWidth = '100%'; i.style.height = 'auto'; i.style.borderRadius = '8px'; });
  body.querySelectorAll('a').forEach(function (a) { a.style.color = 'inherit'; a.style.textDecoration = 'underline'; });
  body.querySelectorAll('blockquote').forEach(function (q) { q.style.borderLeft = '3px solid currentColor'; q.style.margin = '1em 0'; q.style.padding = '0 0 0 14px'; q.style.opacity = '.85'; });
  body.querySelectorAll('pre').forEach(function (p) { p.style.overflow = 'auto'; p.style.fontSize = '.8em'; });

  function iconButton(text, handler) {
    return Skrrt.el('button', { text: text, onclick: handler, style: { all: 'unset', cursor: 'pointer', padding: '10px 14px', font: '700 17px -apple-system,sans-serif', color: 'inherit' } });
  }
  var bar = Skrrt.el('div', {
    style: { position: 'sticky', top: '0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 10px', background: 'inherit', borderBottom: '1px solid rgba(128,128,128,.25)', zIndex: 2 }
  },
    iconButton('✕', close),
    Skrrt.el('div', {},
      iconButton('A−', function () { size = Math.max(14, size - 1); render(); }),
      iconButton('A+', function () { size = Math.min(32, size + 1); render(); }))
  );
  overlay = Skrrt.el('div', { style: { position: 'fixed', inset: '0', overflowY: 'auto', zIndex: 2147483647, webkitOverflowScrolling: 'touch' } }, bar, body);
  document.documentElement.appendChild(overlay);
  document.documentElement.style.overflow = 'hidden';
  render();
}

function close() {
  if (overlay) overlay.remove();
  overlay = null;
  document.documentElement.style.overflow = '';
}

var pill = Skrrt.el('button', {
  text: '☰ ' + (Skrrt.lang === 'ru' ? 'Чтение' : 'Reader'),
  onclick: open,
  style: {
    position: 'fixed', right: '12px', bottom: '96px', zIndex: 2147483646, display: 'none',
    padding: '9px 14px', borderRadius: '999px', border: '1px solid rgba(255,255,255,.25)',
    background: 'rgba(20,20,24,.78)', color: '#fff', font: '600 14px -apple-system,sans-serif'
  }
});
Skrrt.ready(function () { document.documentElement.appendChild(pill); });
Skrrt.every(1500, function () {
  if (overlay) return;
  var found = findArticle();
  pill.style.display = found && found.score > 900 ? 'block' : 'none';
});
