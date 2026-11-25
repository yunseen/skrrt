// Text Size: scales text on every site, like the per-site zoom of desktop browsers.
var percent = Number(Skrrt.options.get('percent', 125));
Skrrt.addStyle('html{-webkit-text-size-adjust:' + percent + '%!important;text-size-adjust:' + percent + '%!important}');
