atom_feed(
  language:  'de-DE',
  root_url: body_feed_url(body: @body),
  url: feed_url_with_current_page(@papers)
) do |feed|
  paginated_feed(feed, @papers)

  down_date = Date.new(2020, 12, 31)
  url = Rails.application.routes.url_helpers.obituary_url

  if !Rails.configuration.x.push_hubs.blank?
    Rails.configuration.x.push_hubs.each do |hub|
      feed.link rel: 'hub', href: hub
    end
  end
  feed.title "kleineAnfragen: Anfragen aus #{@body.name}"
  feed.updated down_date
  feed.author { |author| author.name 'kleineAnfragen' }

  if @papers.first_page?
    feed.entry Paper.new, published: down_date, updated: down_date, url: url do |entry|
      entry.title 'kleineAnfragen wurde abgeschaltet'
      entry.author do |author|
        author.name 'kleineAnfragen'
      end
      entry.summary 'kleineAnfragen wurde nach 5 Jahren Stillstand bei den Parlamenten zum 31.12.2020 abgeschaltet'
    end
  end

  @papers.each do |paper|
    render(partial: 'paper/paper', locals: { feed: feed, paper: paper })
  end
end