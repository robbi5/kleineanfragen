url = paper_url(body: paper.body, legislative_term: paper.legislative_term, paper: paper)
feed.entry paper, published: paper.published_at, updated: paper.updated_at, url: url do |entry|
  # items like in html search result
  title = details[:highlight].try(:fetch, :title, nil).try(:html_safe) || paper.title
  snippet = details[:highlight].try(:fetch, :contents, nil) || ''
  snippet += '&hellip;' unless snippet.blank?

  entry.title do
    feed.cdata! title
  end
  paper.originators.map(&:name).each do |name|
    entry.author { |author| author.name name }
  end
  entry.category(term: paper.body.state, label: paper.body.name)
  entry.summary do
    feed.cdata! paper.description + (!snippet.blank? ? "\n" + snippet : '')
  end
end