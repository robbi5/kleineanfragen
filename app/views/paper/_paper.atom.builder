url = paper_url(body: paper.body, legislative_term: paper.legislative_term, paper: paper)
feed.entry paper, published: paper.published_at, updated: paper.updated_at, url: url do |entry|
  title = paper.title

  if params[:feedformat] == 'twitter'
    title += " (#{paper.originators.map(&:name).join(', ')})" if title.size < 120
  end

  entry.title title
  paper.originators.each do |originator|
    entry.author do |author|
      author.name originator.name
      author.uri organization_url(paper.body, originator) if originator.is_a? Organization
    end
  end
  entry.category(term: paper.body.state, label: paper.body.name)
  entry.summary paper.description
end