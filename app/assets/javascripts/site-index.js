document.addEventListener("turbolinks:load", function() {
  $('.hexmap').addClass('is-interactive');
  $('.hexmap g').hover(function() {
    var state = $(this).attr('id');
    $('.bodies-list a.link-state-' + state).addClass('hover');
  }, function() {
    var state = $(this).attr('id');
    $('.bodies-list a.link-state-' + state).removeClass('hover');
  }).click(function() {
    var state = $(this).attr('id') || $(this).parent().attr('id');
    if (typeof state === 'undefined') return;
    var url = $('.bodies-list a.link-state-' + state).attr('href');
    location.href = url;
  });

  $('.bodies-list a').hover(function() {
    var state = $(this).data('state');
    $('.hexmap g#' + state).addClass('hover');
  }, function() {
    var state = $(this).data('state');
    $('.hexmap g#' + state).removeClass('hover');
  });
});