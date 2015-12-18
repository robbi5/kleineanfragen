require 'test_helper'

class BayernLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BayernLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/by/overview.html')))
  end

  test 'extract first rows from search result page' do
    first_rows = @scraper.extract_first_rows(@html)
    assert_equal 50, first_rows.size
  end

  test 'extract meta from first row' do
    first_row = @scraper.extract_first_rows(@html).first
    meta = @scraper.extract_meta(first_row)
    assert_equal '17/4828', meta[:full_reference]
    assert_equal '09.02.2015', meta[:published_at]
  end

  test 'extract url from link' do
    first_row = @scraper.extract_first_rows(@html).first
    link = @scraper.extract_link(first_row)
    url = @scraper.extract_url(link)
    assert_equal 'http://www1.bayern.landtag.de/ElanTextAblage_WP17/Drucksachen/Schriftliche%20Anfragen/17_0004828.pdf', url
  end

  test 'extract title from third row' do
    first_row = @scraper.extract_first_rows(@html).first
    third_row = first_row.next_element.next_element
    title = @scraper.extract_title(third_row)
    assert_equal 'Einkleidung in den Erstaufnahmeeinrichtungen', title
  end

  test 'extract broken paper should throw error' do
    block = Nokogiri::HTML('<div>Nope.</div>')
    assert_raises RuntimeError do
      @scraper.extract_paper(block)
    end
  end

  test 'extract complete paper' do
    block = @scraper.extract_first_rows(@html).first
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/4828',
        reference: '4828',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Einkleidung in den Erstaufnahmeeinrichtungen',
        url: 'http://www1.bayern.landtag.de/ElanTextAblage_WP17/Drucksachen/Schriftliche%20Anfragen/17_0004828.pdf',
        published_at: Date.parse('09.02.2015'),
        is_answer: true
      }, paper)
  end

  test 'extract complete last paper' do
    block = @scraper.extract_first_rows(@html).last
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/4711',
        reference: '4711',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Verkauf der ehemaligen Haftanstalt "Am Neudeck"',
        url: 'http://www1.bayern.landtag.de/ElanTextAblage_WP17/Drucksachen/Schriftliche%20Anfragen/17_0004711.pdf',
        published_at: Date.parse('29.01.2015'),
        is_answer: true
      }, paper)
  end
end