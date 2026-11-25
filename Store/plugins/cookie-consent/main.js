// Cookie Consent: hides cookie banners and, if you choose, answers them for you.
// Logic follows "I still don't care about cookies": known consent platforms are handled by
// their own buttons, everything else by a generic text match, and anything left is just hidden.
var mode = Skrrt.options.get('mode', 'reject');

var PLATFORMS = [
  { root: '#onetrust-banner-sdk, #onetrust-consent-sdk', reject: '#onetrust-reject-all-handler, .ot-pc-refuse-all-handler', accept: '#onetrust-accept-btn-handler' },
  { root: '#CybotCookiebotDialog', reject: '#CybotCookiebotDialogBodyButtonDecline, #CybotCookiebotDialogBodyLevelButtonLevelOptinDeclineAll', accept: '#CybotCookiebotDialogBodyLevelButtonLevelOptinAllowAll, #CybotCookiebotDialogBodyButtonAccept' },
  { root: '.qc-cmp2-container', reject: '.qc-cmp2-summary-buttons button[mode="secondary"]', accept: '.qc-cmp2-summary-buttons button[mode="primary"]' },
  { root: '#didomi-host, #didomi-popup', reject: '#didomi-notice-disagree-button', accept: '#didomi-notice-agree-button' },
  { root: '.cc-window, .cc-banner', reject: '.cc-deny', accept: '.cc-allow, .cc-dismiss' },
  { root: '#cookiescript_injected', reject: '#cookiescript_reject', accept: '#cookiescript_accept' },
  { root: '#cookie-law-info-bar, #cookie-law-info-again', reject: '#wt-cli-reject-btn, .cli_action_button.wt-cli-reject-btn', accept: '#wt-cli-accept-all-btn, #cookie_action_close_header' },
  { root: '.osano-cm-window, .osano-cm-dialog', reject: '.osano-cm-deny, .osano-cm-denyAll', accept: '.osano-cm-accept-all, .osano-cm-accept' },
  { root: '#iubenda-cs-banner, .iubenda-cs-container', reject: '.iubenda-cs-reject-btn', accept: '.iubenda-cs-accept-btn' },
  { root: '#truste-consent-track, .truste_box_overlay', reject: '#truste-consent-required', accept: '#truste-consent-button' },
  { root: '#cmpbox, #cmpwrapper', reject: '.cmpboxbtnno', accept: '.cmpboxbtnyes' },
  { root: '[id^="sp_message_container"]', reject: '', accept: '' },
  { root: '#CookieConsent, .CookieConsent, #cookie-banner, #cookieBanner, .cookie-banner, .cookie-notice, .cookie-consent', reject: '', accept: '' }
];

var REJECT = /^(reject( all)?|decline( all)?|deny( all)?|refuse( all)?|necessary only|only necessary|essential only|use necessary cookies only|continue without accepting|no,? thanks|отклонить( все)?|только необходимые|отказаться|не соглашаюсь|запретить все|нет,? спасибо|ablehnen|alle ablehnen|refuser|tout refuser|rechazar|rifiuta)$/i;
var ACCEPT = /^(accept( all)?( cookies)?|allow( all)?( cookies)?|agree|i agree|ok|okay|got it|yes,? i agree|accept and close|принять( все)?|согласен|согласна|разрешить( все)?|хорошо|понятно|ок|alle akzeptieren|akzeptieren|accepter|tout accepter|aceptar|accetta)$/i;
var LOOKS_LIKE_BANNER = /cookie|consent|gdpr|ccpa|cmp|privacy[-_ ]?(banner|notice|popup)/i;

var allRoots = PLATFORMS.map(function (p) { return p.root; }).join(',');
Skrrt.addStyle(allRoots + '{opacity:0!important;pointer-events:none!important;max-height:0!important;overflow:hidden!important;z-index:-1!important}', 'hide');

var handled = new WeakSet();

function visibleText(el) {
  return (el.innerText || el.value || el.getAttribute('aria-label') || '').trim().replace(/\s+/g, ' ');
}

function findButton(scope, regex) {
  var nodes = scope.querySelectorAll('button, [role="button"], a, input[type="button"], input[type="submit"]');
  for (var i = 0; i < nodes.length; i++) {
    if (regex.test(visibleText(nodes[i]))) return nodes[i];
  }
  return null;
}

function unlockScroll() {
  [document.documentElement, document.body].forEach(function (e) {
    if (e && getComputedStyle(e).overflow === 'hidden') e.style.setProperty('overflow', 'auto', 'important');
  });
}

function answer(root, platform) {
  if (handled.has(root)) return;
  handled.add(root);
  if (mode === 'hide') { unlockScroll(); return; }
  var target = null;
  if (platform) {
    var wanted = mode === 'accept' ? platform.accept : platform.reject;
    if (wanted) target = root.querySelector(wanted) || document.querySelector(wanted);
  }
  if (!target) target = findButton(root, mode === 'accept' ? ACCEPT : REJECT);
  if (target) {
    try { target.click(); } catch (e) { }
  }
  setTimeout(unlockScroll, 400);
}

function scan() {
  PLATFORMS.forEach(function (platform) {
    var roots = document.querySelectorAll(platform.root);
    for (var i = 0; i < roots.length; i++) answer(roots[i], platform);
  });
  // Generic banners: fixed or sticky elements that talk about cookies.
  var candidates = document.querySelectorAll('div, section, aside, form, dialog');
  for (var j = 0; j < candidates.length; j++) {
    var el = candidates[j];
    if (handled.has(el)) continue;
    if (!LOOKS_LIKE_BANNER.test(el.id + ' ' + el.className)) continue;
    var cs = getComputedStyle(el);
    if (cs.position !== 'fixed' && cs.position !== 'sticky' && cs.position !== 'absolute') continue;
    answer(el, null);
    el.style.setProperty('display', 'none', 'important');
  }
}

var runs = 0;
function tick() {
  scan();
  if (++runs < 24) setTimeout(tick, 500);
}
Skrrt.ready(tick);
