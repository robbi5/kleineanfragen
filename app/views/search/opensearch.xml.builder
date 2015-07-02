xml.instruct!
xml.OpenSearchDescription(:xmlns => 'http://a9.com/-/spec/opensearch/1.1/', 'xmlns:moz' => 'http://www.mozilla.org/2006/browser/search/') do
  xml.ShortName('kleineAnfragen')
  xml.Description('kleineAnfragen Suche')
  xml.InputEncoding('UTF-8')
  xml.Image(root_url.chomp('/') + '/favicon.ico', height: 16, width: 16, type: 'image/x-icon')
  # escape route helper or else it escapes the '{' '}' characters. then search doesn't work
  xml.Url(type: 'text/html', method: 'get', template: CGI::unescape(search_url(q: '{searchTerms}')))
  xml.moz(:SearchForm, root_url)
end