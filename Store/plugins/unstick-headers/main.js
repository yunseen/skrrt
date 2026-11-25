// Unstick Headers: turns bars that stay glued to the top of the page into normal page content.
function sweep() {
  document.querySelectorAll('body *').forEach(function (n) {
    var cs = getComputedStyle(n);
    if ((cs.position === 'fixed' || cs.position === 'sticky') && n.getBoundingClientRect().top < 120 && n.offsetHeight < 220 && n.offsetWidth > innerWidth * 0.5) {
      n.style.setProperty('position', 'static', 'important');
    }
  });
}
Skrrt.ready(function () {
  sweep();
  var runs = 0;
  var id = Skrrt.every(1500, function () { sweep(); if (++runs > 6) clearInterval(id); });
});
