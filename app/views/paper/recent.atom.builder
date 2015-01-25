atom_feed(language:  'de-DE', root_url: recent_url, url: recent_url(format: :atom)) do |feed|
  feed.title "kleineAnfragen: Anfragen der letzten #{@days} Tage"
  feed.updated @papers.maximum(:updated_at)
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.each do |paper|
    render(partial: 'paper', locals: { feed: feed, paper: paper })
  end
end