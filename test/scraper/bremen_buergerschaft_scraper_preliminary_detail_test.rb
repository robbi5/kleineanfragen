require 'test_helper'

class BremenBuergerschaftScraperPreliminaryDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_pre_detail.html')))
  end

  test 'get results from preliminary search results page' do
    results = @scraper.extract_preliminary_results(@html)
    assert_equal 1, results.size
  end

  test 'extract meta information' do
    str = 'Zukunft der BAföG-Ämter im Land Bremen - Antwort des Senats auf die Kleine Anfrage der Fraktion DIE LINKE'
    meta = @scraper.extract_meta_preliminary(str)
    assert_equal(
      {
        title: 'Zukunft der BAföG-Ämter im Land Bremen',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: { people: [], parties: ['DIE LINKE'] },
        answerers: { ministries: ['Senat'] }
      }, meta)
  end

  test 'get full paper' do
    results = @scraper.extract_preliminary_results(@html)
    paper = @scraper.extract_paper_preliminary(results.first)
    assert_equal(
      {
        full_reference: '19/129',
        legislative_term: '19',
        reference: '129',
        title: 'Zukunft der BAföG-Ämter im Land Bremen',
        url: 'https://www.bremische-buergerschaft.de/drs_abo/2015-11-04_Drs-19-129_f88f8.pdf',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: { people: [], parties: ['DIE LINKE'] },
        answerers: { ministries: ['Senat'] }
      }, paper)
  end
end