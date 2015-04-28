module SearchHelper
  def facet_count(key, term)
    terms = @papers.facets[key].try(:fetch, 'terms', nil)
    terms.find { |el| el['term'] == term }.try(:fetch, 'count', nil) unless terms.nil?
  end

  def write_facet_count(key, term)
    count = facet_count(key, term)
    count.present? ? "(#{count})" : ''
  end
end
