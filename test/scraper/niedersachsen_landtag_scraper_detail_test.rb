require 'test_helper'

class NiedersachsenLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = NiedersachsenLandtagScraper
  end

  test 'extract detail info' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/niedersachsen_landtag_scraper_detail.html')))
    block = @scraper.extract_detail_block(@html).first
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/1892',
        reference: '1892',
        title: 'Internetznutzung bei der Polizei - Datenschutz gewährleistet?',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1892.pdf',
        published_at: Date.parse('Tue, 19 Aug 2014'),
        originators: {
          people: ['Jan-Christoph Oetjen'],
          parties: ['FDP']
        },
        answerers: {
          ministries: ['Niedersächsisches Ministerium für Inneres und Sport']
        }
      }, paper)
  end

  test 'extract detail info with attachments' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/niedersachsen_landtag_scraper_detail_attachment.html')))
    block = @scraper.extract_detail_block(@html).first
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/2819',
        reference: '2819',
        title: 'Aktuelle Belegungssituation im niedersächsischen Justizvollzug',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F5000/2501-3000/17-2819.pdf',
        published_at: Date.parse('20.01.2015'),
        originators: {
          people: ['Marco Brunotte', 'Kathrin Wahlmann', 'Andrea Schröder-Ehlers'],
          parties: ['SPD']
        },
        answerers: {
          ministries: ['Niedersächsisches Justizministerium']
        }
      }, paper)
  end
end