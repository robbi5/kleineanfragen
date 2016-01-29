class DetailScraper < Scraper
  def initialize(legislative_term, reference)
    @legislative_term = legislative_term
    @reference = reference
    @sleep = 1
  end

  def full_reference
    @legislative_term.to_s + '/' + @reference.to_s
  end
end