atom_feed(
  language:  'de-DE',
  root_url: ministry_url(body: @body, ministry: @ministry),
  url: ministry_url(body: @body, ministry: @ministry, format: 'atom')
) do |feed|
  feed.title "kleineAnfragen: Anfragen beantwortet von #{@ministry.name}, #{@body.name}"
  feed.updated @papers.maximum(:updated_at)
  feed.author { |author| author.name 'kleineAnfragen' }

  @papers.each do |paper|
    render(partial: 'paper/paper', locals: { feed: feed, paper: paper })
  end
end