// Link Cleaner: removes tracking from links on the page, the way ClearURLs does.
// It strips known tracking parameters and unwraps redirect links of search engines and social networks.
var stripParams = Skrrt.options.get('stripParams', true);
var unwrap = Skrrt.options.get('unwrap', true);

var TRACKING = /^(utm_[a-z]+|fbclid|gclid|dclid|gbraid|wbraid|msclkid|yclid|igshid|mc_eid|mc_cid|mkt_tok|_ga|_gl|vero_id|twclid|ttclid|ref_src|ref_url|spm|oly_enc_id|oly_anon_id|_hsenc|_hsmi|ysclid)$/i;

var REDIRECTS = [
  { host: /(^|\.)google\.[a-z.]+$/, path: '/url', params: ['q', 'url'] },
  { host: /(^|\.)yandex\.[a-z.]+$/, path: /^\/clck\/jsredir/, params: ['to'] },
  { host: /(^|\.)vk\.com$/, path: '/away.php', params: ['to'] },
  { host: /(^|\.)facebook\.com$/, path: '/l.php', params: ['u'] },
  { host: /(^|\.)l\.instagram\.com$/, path: '/', params: ['u'] },
  { host: /(^|\.)out\.reddit\.com$/, path: /.*/, params: ['url'] }
];

function pathMatches(rule, pathname) {
  return rule instanceof RegExp ? rule.test(pathname) : rule === pathname;
}

function clean(a) {
  if (a.dataset.skrrtClean) return;
  a.dataset.skrrtClean = '1';
  a.removeAttribute('ping');
  var u;
  try { u = new URL(a.href, location.href); } catch (e) { return; }
  var changed = false;
  if (unwrap) {
    for (var i = 0; i < REDIRECTS.length; i++) {
      var r = REDIRECTS[i];
      if (r.host.test(u.hostname) && pathMatches(r.path, u.pathname)) {
        for (var k = 0; k < r.params.length; k++) {
          var target = u.searchParams.get(r.params[k]);
          if (target && /^https?:\/\//i.test(target)) {
            try { u = new URL(target); changed = true; } catch (e) { }
            break;
          }
        }
        break;
      }
    }
  }
  if (stripParams) {
    var drop = [];
    u.searchParams.forEach(function (value, key) { if (TRACKING.test(key)) drop.push(key); });
    drop.forEach(function (key) { u.searchParams.delete(key); changed = true; });
  }
  if (changed) a.href = u.toString();
}

Skrrt.observe('a[href]', clean);
