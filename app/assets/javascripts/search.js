$.fn.selectpicker.Constructor.BootstrapVersion = '3';

document.addEventListener("turbolinks:load", function() {
  var papers = new Bloodhound({
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: "/search/autocomplete?q=%QUERY"
  });
  papers.initialize();

  $('#searchq').typeahead({
    minLength: 2,
    highlight: true
  }, {
    name: 'paper',
    displayKey: 'title',
    source: papers.ttAdapter(),
    templates: {
      suggestion: Handlebars.compile('<p>{{title}} <span class="meta">&mdash; {{source}} ({{reference}})</span></p>')
    }
  }).on("typeahead:selected", function(ev, suggestion, dataset) {
    if (suggestion.url) {
      location.href = suggestion.url;
    }
  });

  var submitTimeout, previousValue;

  var selectSubmit = function() {
    $('form.search').submit();
  };

  $('select.selectpicker').not(function(idx, el) {
    return $(el).siblings('.bootstrap-select').size() > 0;
  }).selectpicker({
      iconBase: '',
      tickIcon: 'selected-tick',
      styleBase: 'btn form-control',
      showTick: true
  }).on('show.bs.select', function (el) {
    if (submitTimeout) clearTimeout(submitTimeout);
    previousValue = Array.from(this.selectedOptions || []).map(function(opt){ return opt.value; }).join(',');
  }).on('hide.bs.select', function (el) {
    currentValue = Array.from(this.selectedOptions || []).map(function(opt){ return opt.value; }).join(',');
    if (previousValue != currentValue) {
      submitTimeout = setTimeout(selectSubmit, 500);
    }
  });

  $('form.search input[type=checkbox]').on('change', function() {
    submitTimeout = setTimeout(selectSubmit, 500);
  });
});