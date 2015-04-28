require 'test_helper'

class HamburgBuergerschaftScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = HamburgBuergerschaftScraper
  end

  test 'extract paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hamburg_search_result.html')))
    paper = @scraper.extract(@html.css('.title').first)
    assert_equal(
      {
        legislative_term: '21',
        full_reference: '21/159',
        reference: '159',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Wann werden endlich die Bahnhofsknotenpunkte Hamburg und Harburg entlastet und Pendler sowie die Harburgerinnen und Harburger nicht mehr länger wie Ölsardinen in Züge gepresst?',
        url: 'https://www.buergerschaft-hh.de/ParlDok/dokument/48286/wann-werden-endlich-die-bahnhofsknotenpunkte-hamburg-und-harburg-entlastet-und-pendler-sowie-die-harburgerinnen-und-harburger-nicht-mehr-l%C3%A4nger.pdf',
        published_at: Date.parse('2015-03-31'),
        originators: {
          people: ['Birgit Stöver'],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Senat']
        }
      }, paper)
  end
end