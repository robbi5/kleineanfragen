require 'test_helper'

class SaarlandScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = SaarlandScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/saarland_scraper_detail.html')))
  end

  test 'build text parameter' do
    assert_equal 'k=Aw14_0320', @scraper.build_text_parameter('14', '0320')
  end

  test 'extract entry from search result' do
    entry = @scraper.extract_search_entry(@html, '14', '0374')
    assert_equal({
                   title: 'Biogasanlagen im Saarland',
                   description: 'LANDTAG DES SAARLANDES 14. Wahlperiode Drucksache 14/374 (14/334) 06.01.2011 A N T W O R T zu der Anfrage der Abgeordneten Anke Rehlinger (SPD) Dr. Magnus Jung (SPD) betr',
                   url: 'http://www.landtag-saar.de/Dokumente/DrucksachenNEU/Aw14_0374.pdf'
                 }, entry)
    assert_equal 'Biogasanlagen im Saarland', entry[:title]
  end

  test 'extract paper from search result' do
    mp = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/saarland_scraper_detail.html')))
    entry = @scraper.extract_search_entry(mp, '14', '0374')
    paper = @scraper.extract_paper_from_search_entry(entry, '14', '0374')
    assert_equal(
      {
        legislative_term: '14',
        full_reference: '14/0374',
        reference: '0374',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Biogasanlagen im Saarland',
        url: 'http://www.landtag-saar.de/Dokumente/DrucksachenNEU/Aw14_0374.pdf',
        published_at: Date.parse('2011-01-06'),
        is_answer: true
      }, paper)
  end
end