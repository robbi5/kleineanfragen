require 'test_helper'

class BremenBuergerschaftScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
  end

  test 'extract detail info for minor' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_543.html')))
    details = @scraper.extract_paper_detail(@html)
    assert_equal(
      {
        published_at: Date.parse('14.08.2012'),
        originators: {
          people: [],
          parties: ['SPD']
        }
      }, details)
  end

  test 'extract detail info for minor with party "Die Grünen"' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_115.html')))
    details = @scraper.extract_paper_detail(@html)
    assert_equal(
      {
        published_at: Date.parse('03.04.2012'),
        originators: {
          people: [],
          parties: ['Bündnis 90/Die Grünen']
        }
      }, details)
  end

  test 'extract detail info for major' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_71.html')))
    details = @scraper.extract_paper_detail(@html)
    assert_equal(
      {
        published_at: Date.parse('22.12.2011'),
        originators: {
          people: [],
          parties: ['CDU']
        }
      }, details)
  end

  test 'extract detail info for major with more parties' do
      @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_74.html')))
      details = @scraper.extract_paper_detail(@html)
      assert_equal(
        {
          published_at: Date.parse('10.01.2012'),
          originators: {
            people: [],
            parties: ['Bündnis 90/Die Grünen', 'SPD']
          }
        }, details)
  end

  test 'extract detail info for major with a different pattern' do
      @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_36.html')))
      details = @scraper.extract_paper_detail(@html)
      assert_equal(
        {
          published_at: Date.parse('04.10.2011'),
          originators: {
            people: [],
            parties: ['CDU']
          }
        }, details)
  end
end