// Same Tab: links that ask for a new window open in the current tab instead.
document.addEventListener('click', function (event) {
  var link = event.target.closest && event.target.closest('a[target]');
  if (link && link.target === '_blank') link.removeAttribute('target');
}, true);
Skrrt.observe('a[target="_blank"]', function (a) { a.removeAttribute('target'); });
