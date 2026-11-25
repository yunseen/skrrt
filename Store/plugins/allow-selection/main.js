// Allow Copy and Selection: unlocks text selection, copy and the context menu on sites that block them.
Skrrt.addStyle('*{-webkit-user-select:text!important;user-select:text!important;-webkit-touch-callout:default!important}');
['copy', 'cut', 'paste', 'contextmenu', 'selectstart', 'dragstart', 'mousedown'].forEach(function (type) {
  document.addEventListener(type, function (event) { event.stopImmediatePropagation(); }, true);
});
