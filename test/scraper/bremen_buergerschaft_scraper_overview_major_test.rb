require 'test_helper'

class BremenBuergerschaftScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_overview_major.html')))
  end

  test 'get search results from resultpage' do
    results = @scraper.extract_results(@html)
    assert_equal 182, results.size
  end

  test 'get full_reference from from a result-row' do
    results = @scraper.extract_results(@html)
    full_reference = @scraper.extract_full_reference(results.first)
    assert_equal '18/36 S', full_reference
  end

  test 'get reference and legislative term from full_reference' do
    results = @scraper.extract_results(@html)
    full_reference = @scraper.extract_full_reference(results.first)
    legislative_term, reference = @scraper.extract_reference(full_reference)
    assert_equal '18', legislative_term
    assert_equal '36 S', reference
  end

  test 'get title from result-row' do
    results = @scraper.extract_results(@html)
    title = @scraper.extract_title(results.first)
    assert_equal 'Zwischenbericht zum Finanzierungskonzept des Teilersatzneubaus am Klinikum Bremen-Mitte', title
  end

  test 'get url from result-row' do
    results = @scraper.extract_results(@html)
    url = @scraper.extract_url(results.first)
    assert_equal 'https://www.bremische-buergerschaft.de/fileadmin/volltext.php?area=&np=&navi=informationsdienste5&buergerschaftart=2&dn=D18S0036.DAT&lp=18&format=pdf&edatum=2011-10-04', url
  end

  test 'extract doctype from result-row' do
    results = @scraper.extract_results(@html)
    doctype = @scraper.extract_doctype(results.first)
    assert_equal 'major', doctype
  end

  test 'extract paper' do
    results = @scraper.extract_results(@html)
    paper = @scraper.extract_paper(results.first)
    assert_equal(
      {
        legislative_term: '18',
        full_reference: '18/36 S',
        reference: '36 S',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Zwischenbericht zum Finanzierungskonzept des Teilersatzneubaus am Klinikum Bremen-Mitte',
        url: 'https://www.bremische-buergerschaft.de/fileadmin/volltext.php?area=&np=&navi=informationsdienste5&buergerschaftart=2&dn=D18S0036.DAT&lp=18&format=pdf&edatum=2011-10-04',
        is_answer: true,
        answerers: {
          ministries: ['Senat']
        }
      }, paper)
  end
end