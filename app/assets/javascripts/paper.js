document.addEventListener("turbolinks:load", function() {
  $('.shorturl-input').focus(function() {
    $(this).select();
  });
});