atom_feed(
  language: 'de-DE',
  root_url: search_url(q: @query),
  url: feed_url_with_current_page(@papers, q: @query),
  id: search_feed_id(@query, params[:page]),
  'xmlns:opensearch' => 'http://a9.com/-/spec/opensearch/1.1/'
) do |feed|
  paginated_feed(feed, @papers, q: @query)
  feed.title "kleineAnfragen: Suche nach #{@term}"
  feed.updated @papers.map(&:updated_at).max
  feed.author { |author| author.name 'kleineAnfragen' }
  feed.link href: opensearch_path, rel: 'search', type: 'application/opensearchdescription+xml'
  feed.tag!('opensearch:totalResults', @papers.total_count)
  feed.tag!('opensearch:Query', role: 'request', searchTerms: @query)

  @papers.each do |paper|
    render(partial: 'searchresult', locals: { feed: feed, paper: paper })
  end
end