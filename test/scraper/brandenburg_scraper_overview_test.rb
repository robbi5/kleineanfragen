require 'test_helper'

class BrandenburgScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BrandenburgLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/brandenburg_scraper_overview.html')))
  end

  test 'extract seperators from search result page' do
    body = @scraper.extract_body(@html)
    items = @scraper.extract_items(body)
    assert_equal 50, items.size
  end

  test 'extract title from next row' do
    body = @scraper.extract_body(@html)
    item = @scraper.extract_items(body).first
    title = @scraper.extract_title(item)
    assert_equal 'Wohngeldzuschuss', title
  end

  test 'extract originators' do
    body = @scraper.extract_body(@html)
    item = @scraper.extract_items(body).first
    meta_block = @scraper.extract_meta_block(item)
    meta_rows = @scraper.extract_meta_rows(meta_block)
    originators = @scraper.extract_originators(meta_rows.first)
    assert_equal 'Anita Tack', originators[:people][0]
    assert_equal 'DIE LINKE', originators[:parties][0]
  end

  test 'extract published_at' do
    body = @scraper.extract_body(@html)
    item = @scraper.extract_items(body).first
    meta_block = @scraper.extract_meta_block(item)
    meta_rows = @scraper.extract_meta_rows(meta_block)
    published_at = @scraper.extract_published_at(meta_rows.last)
    assert_equal Date.parse('2015-03-19'), published_at
  end

  test 'extract complete paper' do
    body = @scraper.extract_body(@html)
    item = @scraper.extract_items(body).last
    paper = @scraper.extract_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/885',
        reference: '885',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Sanierung von Ortsdurchfahrten entlang der Landesstraßen 154 und 155',
        url: 'http://www.parldok.brandenburg.de/parladoku/w6/drs/ab_0800/885.pdf',
        published_at: Date.parse('2015-03-16'),
        originators: { people: ['Dr. Jan Redmann', 'Rainer Genilke'], parties: ['CDU'] },
        is_answer: true
      }, paper)
  end
end