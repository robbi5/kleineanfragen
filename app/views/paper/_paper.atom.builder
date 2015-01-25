url = paper_url(body: paper.body, legislative_term: paper.legislative_term, paper: paper)
feed.entry paper, published: paper.published_at, updated: paper.updated_at, url: url do |entry|
  entry.title paper.title
  paper.originators.collect(&:name).each do |name|
    entry.author { |author| author.name name }
  end
  entry.category(term: paper.body.state, label: paper.body.name)
  entry.summary paper.description
end