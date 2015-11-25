require 'test_helper'

class BremenBuergerschaftScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_overview.html')))
  end

  test 'get search results from resultpage' do
    items = @scraper.extract_records(@html)
    assert_equal 24, items.size
  end

  test 'get title from result-row' do
    item = @scraper.extract_records(@html).first
    title = @scraper.extract_title(item)
    assert_equal 'Fuhrparkkonzept der Polizei Bremen', title
  end

  test 'get link from from a result-row' do
    item = @scraper.extract_records(@html).first
    meta_rows = @scraper.extract_meta_rows(item)
    link = @scraper.extract_link(meta_rows)
    assert_equal '19/47', @scraper.extract_full_reference(link)
    assert_equal 'http://www.bremische-buergerschaft.de/dokumente/wp19/land/drucksache/D19L0047.pdf', @scraper.extract_url(link)
  end

  test 'extract doctype from result-row' do
    item = @scraper.extract_records(@html).first
    meta_rows = @scraper.extract_meta_rows(item)
    meta = @scraper.extract_meta(meta_rows)
    assert_equal Paper::DOCTYPE_MINOR_INTERPELLATION, meta[:doctype]
  end

  test 'extract minor paper' do
    items = @scraper.extract_records(@html)
    paper = @scraper.extract_paper(items.first)
    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/47',
        reference: '47',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Fuhrparkkonzept der Polizei Bremen',
        url: 'http://www.bremische-buergerschaft.de/dokumente/wp19/land/drucksache/D19L0047.pdf',
        published_at: Date.parse('2015-08-25'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Senat']
        },
        is_answer: true
      }, paper)
  end

  test 'extract major paper' do
    items = @scraper.extract_records(@html)
    paper = @scraper.extract_paper(items[15])
    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/123',
        reference: '123',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Jacobs University Bremen – Sachstand, Herausforderungen und Chancen',
        url: 'http://www.bremische-buergerschaft.de/dokumente/wp19/land/drucksache/D19L0123.pdf',
        published_at: Date.parse('2015-10-27'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Senat']
        },
        is_answer: true
      }, paper)
  end
end