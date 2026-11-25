// YouTube Ad Skipper: hides ad slots and fast-forwards video ads.
var autoSkip = Skrrt.options.get('autoSkip', true);
var muteAds = Skrrt.options.get('muteAds', true);

Skrrt.addStyle([
  '.ytp-ad-overlay-container', '.ytp-ad-module', '#player-ads', '#masthead-ad',
  'ytd-display-ad-renderer', 'ytd-promoted-sparkles-web-renderer', 'ytd-ad-slot-renderer',
  'ytd-banner-promo-renderer', 'ytd-in-feed-ad-layout-renderer', 'ytd-statement-banner-renderer',
  'ytm-promoted-sparkles-web-renderer', 'ytm-promoted-video-renderer', 'ytm-companion-slot',
  '.ytp-ad-image-overlay', '.video-ads'
].join(',') + '{display:none!important}');

var mutedByUs = false;
Skrrt.every(350, function () {
  var player = document.querySelector('.html5-video-player');
  var video = document.querySelector('video.html5-main-video') || document.querySelector('video');
  if (!player || !video) return;
  if (player.classList.contains('ad-showing') || player.classList.contains('ad-interrupting')) {
    if (muteAds && !video.muted) { video.muted = true; mutedByUs = true; }
    if (autoSkip) {
      if (isFinite(video.duration) && video.duration > 0 && video.duration < 180) video.currentTime = video.duration;
      var skip = document.querySelector('.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button, .ytp-ad-skip-button-container button');
      if (skip) skip.click();
    }
  } else if (mutedByUs) {
    video.muted = false;
    mutedByUs = false;
  }
});
