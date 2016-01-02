atom_feed(
  language: 'de-DE',
  root_url: organization_url(body: @body, organization: @organization),
  url: feed_url_with_current_page(@papers)
) do |feed|
  paginated_feed(feed, @papers)
  feed.title "kleineAnfragen: Anfragen gestellt von #{@organization.name}, #{@body.name}"
  feed.updated @papers.maximum(:updated_at)
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.each do |paper|
    render(partial: 'paper/paper', locals: { feed: feed, paper: paper })
  end
end