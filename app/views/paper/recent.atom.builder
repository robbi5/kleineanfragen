atom_feed(language:  'de-DE', root_url: recent_url, url: recent_url(format: 'atom')) do |feed|
  feed.title "kleineAnfragen: Anfragen der letzten #{@days} Tage"
  feed.updated @papers.maximum(:updated_at)

  @papers.each do |paper|
    url = paper_url(body: paper.body, legislative_term: paper.legislative_term, paper: paper)
    feed.entry paper, published: paper.published_at, updated: paper.updated_at, url: url do |entry|
      entry.title paper.title
      paper.originators.collect(&:name).each do |name|
        entry.author { |author| author.name name }
      end
      entry.category(term: paper.body.state, label: paper.body.name)
      entry.url url
      entry.summary paper.description
    end
  end
end