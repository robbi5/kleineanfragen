$(document).on('page:change', function() {
  if (window._paq != null) {
    return _paq.push(['trackPageView']);
  } else if (window.piwikTracker != null) {
    return piwikTracker.trackPageview();
  }
});