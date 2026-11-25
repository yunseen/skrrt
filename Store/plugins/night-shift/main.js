// Night Shift: a warm tint and optional dimming over every page.
var warmth = Number(Skrrt.options.get('warmth', 25));
var dim = Number(Skrrt.options.get('dim', 0));

var css = 'html::after{content:"";position:fixed;inset:0;pointer-events:none;z-index:2147483647;' +
  'background:rgba(255,140,0,' + (warmth / 100 * 0.55).toFixed(3) + ');mix-blend-mode:multiply}';
if (dim > 0) {
  css += 'html::before{content:"";position:fixed;inset:0;pointer-events:none;z-index:2147483647;background:rgba(0,0,0,' + (dim / 100).toFixed(3) + ')}';
}
Skrrt.addStyle(css);
