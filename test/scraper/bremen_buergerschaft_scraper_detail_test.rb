require 'test_helper'

class BremenBuergerschaftScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = BremenBuergerschaftScraper
  end

  test 'extract whole major paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bremen_buergerschaft_scraper_detail_96.html')))
    items = @scraper.extract_records(@html)
    paper = @scraper.extract_paper(items.first)
    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/96',
        reference: '96',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Kann Bremen seinen Verpflichtungen im Bereich Kinderschutz noch ausreichend nachkommen?',
        url: 'http://www.bremische-buergerschaft.de/dokumente/wp19/land/drucksache/D19L0096.pdf',
        published_at: Date.parse('2015-10-06'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Senat']
        },
        is_answer: true
      }, paper)
  end
end