$(function(){
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
});