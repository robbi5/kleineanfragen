require 'test_helper'

class BayernLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = BayernLandtagScraper
  end

  test 'extract detail info' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bayern_landtag_scraper_detail.html')))
    block = @scraper.extract_first_rows(@html).first
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/4838',
        reference: '4838',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Finanz- und Heimatempfänge',
        url: 'http://www1.bayern.landtag.de/ElanTextAblage_WP17/Drucksachen/Schriftliche%20Anfragen/17_0004838.pdf',
        published_at: Date.parse('09.02.2015'),
        originators: {
          parties: ['BÜNDNIS 90/DIE GRÜNEN']
        }
      }, paper)
  end
end