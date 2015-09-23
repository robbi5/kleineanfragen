atom_feed(
  language: 'de-DE',
  root_url: search_url(q: @query),
  url: feed_url_with_current_page(@papers, q: @query),
  id: search_feed_id(@query, params[:page])
) do |feed|
  paginated_feed(feed, @papers, q: @query)
  feed.title "kleineAnfragen: Suche nach #{@term}"
  feed.updated @papers.map(&:updated_at).max
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.with_details.each do |paper, details|
    render(partial: 'searchresult', locals: { feed: feed, paper: paper, details: details })
  end
end