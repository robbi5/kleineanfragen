// when application.js is loaded async the DOMContentLoaded event sometimes already happened
// if this is the case, readyState is interactive/complete - so we can trigger the turbolinks start manually
if (document.readyState === "interactive" || document.readyState === "complete") {
  Turbolinks.controller.pageLoaded();
}