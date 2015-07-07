require 'test_helper'

class SachsenScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = SachsenScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sachsen_scraper_overview.html')))
  end

  test 'extract meta data for minor interpellation' do
    text = 'KlAnfr Vorname Nachname PARTEI 29.05.2015 Drs 19/1234'
    assert_equal(
      {
        person: 'Vorname Nachname',
        party: 'PARTEI',
        published_at: Date.parse('2015-05-29'),
        full_reference: '19/1234'
      },
      @scraper.extract_meta_data(text))
  end

  test 'extract meta data for minor interpellation with spaced party' do
    text = 'KlAnfr Vorname Nachname DIE PARTEI 29.05.2015 Drs 19/1234'
    assert_equal(
      {
        person: 'Vorname Nachname',
        party: 'DIE PARTEI',
        published_at: Date.parse('2015-05-29'),
        full_reference: '19/1234'
      },
      @scraper.extract_meta_data(text))
  end

  test 'extract meta data for minor interpellation with mixed case party' do
    text = 'KlAnfr Vorname Nachname AbC 29.05.2015 Drs 19/1234'
    assert_equal(
      {
        person: 'Vorname Nachname',
        party: 'AbC',
        published_at: Date.parse('2015-05-29'),
        full_reference: '19/1234'
      },
      @scraper.extract_meta_data(text))
  end

  test 'extract meta data for major interpellation' do
    text = 'GrAnfr PARTEI 29.05.2015 Drs 19/1234'
    assert_equal(
      {
        person: nil,
        party: 'PARTEI',
        published_at: Date.parse('2015-05-29'),
        full_reference: '19/1234'
      },
      @scraper.extract_meta_data(text))
  end

  test 'extract items' do
    items = SachsenScraper.extract_overview_items(@html)
    assert_equal 20, items.size
  end

  test 'extract paper' do
    item = SachsenScraper.extract_overview_items(@html).last
    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/1258',
        reference: '1258',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Modellbetriebe naturgemäßere Waldbewirtschaftung in Sachsen',
        url: nil,
        published_at: Date.parse('2015-03-27'),
        originators: {
          people: ['Wolfram Günther'],
          parties: ['GRÜNE']
        },
        is_answer: nil
      },
      @scraper.extract_detail_paper(item))
  end
end