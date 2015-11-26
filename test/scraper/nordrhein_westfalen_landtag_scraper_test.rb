require 'test_helper'

class NordrheinWestfalenLandtagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = NordrheinWestfalenLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nordrhein_westfalen_landtag_scraper_overview.html')))
  end

  test 'extract complete paper' do
    block = @scraper.extract_blocks(@html).first
    paper = @scraper.extract_paper(block, resolve_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/8512',
        reference: '8512',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Wie positioniert sich die Landesregierung zu den Forderungen der Gesundheitsministerin für eine kontrollierte Freigabe von Cannabis?',
        url: 'http://www.landtag.nrw.de/portal/WWW/dokumentenarchiv/Dokument?Id=MMD16/8512%7C1%7C0',
        published_at: Date.parse('2015-04-24'),
        originators: nil,
        is_answer: true,
        answerers: { ministries: ['MGEPA'] }
      }, paper)
  end

  test 'extract all papers' do
    @scraper.extract_blocks(@html).each do |block|
      paper = @scraper.extract_paper(block, resolve_pdf: false)
      assert !paper.nil?, block.text
    end
  end

  test 'extract additional paper details' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nordrhein_westfalen_landtag_scraper_detail.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper_details(block)

    assert_equal(
      {
        originators: { people: ['Peter Preuß'], parties: ['CDU'] }
      }, paper)
  end

  test 'extract additional paper details from major interpellation' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nordrhein_westfalen_landtag_scraper_detail_7452.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper_details(block)

    assert_equal ['CDU'], paper[:originators][:parties]
  end

  test 'extract originators from major paper with a four names and two parties' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nordrhein_westfalen_landtag_scraper_detail_7576.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper_details(block)

    assert_equal(
      {
        originators: {
          people: ['Norbert Römer', 'Marc Herter', 'Reiner Priggen', 'Sigrid Beer'],
          parties: ['SPD', 'GRÜNE']
        }
      }, paper)
  end

  test 'regression, was invalid date, 16/8774' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nordrhein_westfalen_landtag_scraper_overview_16_8774.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper(block)

    assert_equal Date.parse('2015-05-27'), paper[:published_at]
  end
end
