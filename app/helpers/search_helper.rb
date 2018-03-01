module SearchHelper
  def facet_count(key, term)
    terms = @papers.aggs.try(:[], key).try(:fetch, 'buckets', nil)
    terms.find { |el| el['key'] == term }.try(:fetch, 'doc_count', nil) unless terms.nil?
  end

  def write_facet_count(key, term)
    count = facet_count(key, term)
    count.present? ? "(#{number_with_delimiter(count)})" : ''
  end

  # look into actionview / atom_feed_helper
  def search_feed_id(query, page = nil)
    schema_date = "2005" # The Atom spec copyright date
    "tag:#{request.host},#{schema_date}:#{request.fullpath.split('.')[0]},query:#{query}" + (!page.nil? ? ",page:#{page}" : '')
  end
end
