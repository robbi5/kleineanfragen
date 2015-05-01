require 'test_helper'

class ThueringenLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = ThueringenLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/thueringen_landtag_scraper_detail_minor.html')))
  end

  test 'extract detail info' do
    originators = @scraper.extract_paper_detail(@html)
    assert_equal(
      {
        originators: {
          people: ['Andreas Bühl'],
          parties: ['CDU']
        }
      }, originators)
  end
end