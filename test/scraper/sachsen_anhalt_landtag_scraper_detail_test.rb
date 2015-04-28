require 'test_helper'

class SachsenAnhaltLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = SachsenAnhaltLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sachsen_anhalt_landtag_scraper_detail.html')))
  end

  test 'extract detail info' do
    item = @scraper.extract_detail_block(@html)
    paper = @scraper.extract_detail_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/3801',
        reference: '3801',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Wirtschaftliche Entwicklung Sachsen-Anhalts',
        url: 'http://padoka.landtag.sachsen-anhalt.de/files/drs/wp6/drs/d3801lag.pdf',
        published_at: Date.parse('2015-02-09'),
        originators: {
          people: [],
          parties: ['SPD']
        },
        is_answer: true,
        answerers: {
          ministries: ['Landesregierung']
        }
      }, paper)
  end
end