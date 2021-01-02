atom_feed(language:  'de-DE', root_url: recent_url) do |feed|
  down_date = Date.new(2020, 12, 31)
  url = Rails.application.routes.url_helpers.obituary_url

  feed.title "kleineAnfragen: Anfragen der letzten Tage"
  feed.updated down_date
  feed.author { |author| author.name 'kleineAnfragen' }

  feed.entry Paper.new, published: down_date, updated: down_date, url: url do |entry|
    entry.title 'kleineAnfragen wurde abgeschaltet'
    entry.author do |author|
      author.name 'kleineAnfragen'
    end
    entry.summary 'kleineAnfragen wurde nach 5 Jahren Stillstand bei den Parlamenten zum 31.12.2020 abgeschaltet'
  end
end