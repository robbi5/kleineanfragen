atom_feed(
  language:  'de-DE',
  root_url: legislative_term_url(body: @body, legislative_term: @legislative_term),
  url: legislative_term_url(body: @body, legislative_term: @legislative_term, format: 'atom')
) do |feed|
  feed.title "kleineAnfragen: Anfragen aus #{@body.name}, #{@legislative_term}. Wahlperiode"
  feed.updated @papers.maximum(:updated_at)
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.each do |paper|
    render(partial: 'paper/paper', locals: { feed: feed, paper: paper })
  end
end