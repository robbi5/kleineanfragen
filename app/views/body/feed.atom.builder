atom_feed(
  language:  'de-DE',
  root_url: body_feed_url(body: @body),
  url: feed_url_with_current_page(@papers)
) do |feed|
  paginated_feed(feed, @papers)
  if !Rails.configuration.x.push_hubs.blank?
    Rails.configuration.x.push_hubs.each do |hub|
      feed.link rel: 'hub', href: hub
    end
  end
  feed.title "kleineAnfragen: Anfragen aus #{@body.name}"
  feed.updated @papers.maximum(:updated_at)
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.each do |paper|
    render(partial: 'paper/paper', locals: { feed: feed, paper: paper })
  end
end