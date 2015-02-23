require 'test_helper'

class RheinlandPfalzLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = RheinlandPfalzLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail.html')))
  end

  test 'extract complete paper' do
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4608',
        reference: '4608',
        title: 'Grundversorgung mit leistungsfähigem Breitband im Wahlkreis 29',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4608-16.pdf',
        published_at: Date.parse('13.02.2015'),
        originators: { people: ['Dorothea Schäfer'], parties: ['CDU'] },
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] }
      }, paper)
  end

  test 'extract paper with additional link like in 16/4097' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail_4097.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4097',
        reference: '4097',
        title: 'Laufende Beihilfeverfahren/Antwort der Landesregierung',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4097-16.pdf',
        published_at: Date.parse('14.10.2014'),
        originators: { people: ['Alexander Licht'], parties: ['CDU'] },
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] }
      }, paper)
  end
end