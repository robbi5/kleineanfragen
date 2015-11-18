require 'test_helper'

class BremenBuergerschaftScraperPreliminaryOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_pre_overview.html')))
  end

  test 'get results from preliminary search results page' do
    results = @scraper.extract_preliminary_results(@html)
    assert_equal 30, results.size
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

  test 'get first full paper' do
    results = @scraper.extract_preliminary_results(@html)
    paper = @scraper.extract_paper_preliminary(results.first)
    assert_equal(
      {
        full_reference: '19/137',
        legislative_term: '19',
        reference: '137',
        title: 'Schulische Situation von geflüchteten Kindern und Jugendlichen',
        url: 'https://www.bremische-buergerschaft.de/drs_abo/2015-11-11_Drs-19-137_11c48.pdf',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        originators: { people: [], parties: ['DIE LINKE'] },
        answerers: { ministries: ['Senat'] }
      }, paper)
  end

  test 'get last full paper' do
    results = @scraper.extract_preliminary_results(@html)
    paper = @scraper.extract_paper_preliminary(results.last)
    assert_equal(
      {
        full_reference: '18/694 S',
        legislative_term: '18',
        reference: '694 S',
        title: 'Unterdeckung bei Kosten der Unterkunft',
        url: 'https://www.bremische-buergerschaft.de/drs_abo/2015-04-21_Drs-18-694%20S_9078f.pdf',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: { people: [], parties: ['DIE LINKE'] },
        answerers: { ministries: ['Senat'] }
      }, paper)
  end
end