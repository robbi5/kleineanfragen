url = paper_url(body: paper.body, legislative_term: paper.legislative_term, paper: paper)
feed.entry paper, published: paper.published_at, updated: paper.updated_at, url: url do |entry|
  entry.title paper.title
  paper.originators.each do |originator|
    entry.author do |author|
      author.name originator.name
      author.uri organization_url(paper.body, originator) if originator.is_a? Organization
    end
  end
  entry.category(term: paper.body.state, label: paper.body.name)
  entry.summary paper.description
end