// SponsorBlock: skips sponsor segments, intros and similar parts of YouTube videos.
// Segments come from the community database at sponsor.ajay.app. Only the first four characters
// of the hashed video id are sent (the privacy variant of the API), and the full match is made here.
var cats = Skrrt.options.get('categories', ['sponsor', 'selfpromo', 'interaction']);
var autoSkip = Skrrt.options.get('autoSkip', true);
var notify = Skrrt.options.get('toast', true);

var NAMES = {
  sponsor: { en: 'Sponsor', ru: 'Спонсор' },
  selfpromo: { en: 'Self promotion', ru: 'Самореклама' },
  interaction: { en: 'Reminder to subscribe', ru: 'Просьба подписаться' },
  intro: { en: 'Intro', ru: 'Заставка' },
  outro: { en: 'Outro', ru: 'Концовка' },
  preview: { en: 'Preview', ru: 'Анонс' },
  music_offtopic: { en: 'Off-topic music', ru: 'Не по теме' }
};

var state = { id: null, segments: [], skipped: {} };

function videoId() {
  var u = new URL(location.href);
  if (u.pathname === '/watch') return u.searchParams.get('v');
  var m = u.pathname.match(/^\/(shorts|embed|live)\/([\w-]{11})/);
  return m ? m[2] : null;
}

function sha256Hex(text) {
  return crypto.subtle.digest('SHA-256', new TextEncoder().encode(text)).then(function (buffer) {
    return Array.prototype.map.call(new Uint8Array(buffer), function (b) {
      return ('0' + b.toString(16)).slice(-2);
    }).join('');
  });
}

function load(id) {
  state = { id: id, segments: [], skipped: {} };
  if (!id || !cats.length) return;
  sha256Hex(id).then(function (hash) {
    var url = 'https://sponsor.ajay.app/api/skipSegments/' + hash.slice(0, 4) +
      '?categories=' + encodeURIComponent(JSON.stringify(cats)) +
      '&actionTypes=' + encodeURIComponent(JSON.stringify(['skip']));
    return Skrrt.fetch(url);
  }).then(function (response) {
    if (!response.ok) return null;
    return response.json();
  }).then(function (list) {
    if (state.id !== id || !Array.isArray(list)) return;
    var entry = list.filter(function (item) { return item.videoID === id; })[0];
    state.segments = entry ? entry.segments : [];
    Skrrt.log('segments', state.segments.length);
  }).catch(function (error) {
    Skrrt.log('could not load segments', error && error.message);
  });
}

function tick() {
  var id = videoId();
  if (id !== state.id) load(id);
  if (!id || !state.segments.length || !autoSkip) return;
  var video = document.querySelector('video.html5-main-video') || document.querySelector('video');
  if (!video || video.paused && video.currentTime === 0) return;
  var now = video.currentTime;
  state.segments.forEach(function (item) {
    var start = item.segment[0], end = item.segment[1];
    if (now >= start && now < end - 0.25) {
      var last = state.skipped[item.UUID] || 0;
      if (Date.now() - last < 3000) return;
      state.skipped[item.UUID] = Date.now();
      video.currentTime = end;
      if (notify) {
        var name = (NAMES[item.category] || { en: item.category, ru: item.category })[Skrrt.lang === 'ru' ? 'ru' : 'en'];
        Skrrt.toast((Skrrt.lang === 'ru' ? 'Пропущено: ' : 'Skipped: ') + name, 2000);
      }
    }
  });
}

Skrrt.every(250, tick);
