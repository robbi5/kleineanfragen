require 'test_helper'

class BerlinAghScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = BerlinAghScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/berlin_agh_scraper_detail.html')))
  end

  test 'extract complete paper' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    paper = @scraper.extract_paper(seperator)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/14146',
        reference: '14146',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Videoüberwachung in Berliner Kitas?',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-14146.pdf',
        published_at: Date.parse('14.07.2014'),
        originators: { people: ['Susanne Graf'], parties: ['Piraten'] },
        answerers: { ministries: ['SenBildJugWiss'] }
      }, paper)
  end
end