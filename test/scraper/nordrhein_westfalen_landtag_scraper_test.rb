require 'test_helper'

class NordrheinWestfalenLandtagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = NordrheinWestfalenLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nw/overview.html')))
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

  test 'extract complete paper with different date text' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nw/detail_8774.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper(block, resolve_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/8774',
        reference: '8774',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Unterrichtsbedingungen an Schulen der Stadt Bottrop - Wie sieht die aktuelle Faktenlage aus zur Unterrichtsversorgung, zum Personalbedarf, zum Altersdurchschnitt der Lehrerkollegien und zu den Klassengrößen?',
        url: 'http://www.landtag.nrw.de/portal/WWW/dokumentenarchiv/Dokument?Id=MMD16/8774%7C1%7C0',
        published_at: Date.parse('2015-05-27'),
        originators: nil,
        is_answer: true,
        answerers: { ministries: ['MSW'] }
      }, paper)
  end

  test 'extract all papers' do
    @scraper.extract_blocks(@html).each do |block|
      paper = @scraper.extract_paper(block, resolve_pdf: false)
      assert !paper.nil?, block.text
    end
  end

  test 'extract additional paper details' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nw/detail.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper_details(block)

    assert_equal(
      {
        originators: { people: ['Peter Preuß'], parties: ['CDU'] }
      }, paper)
  end

  test 'extract additional paper details from major interpellation' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nw/detail_7452.html')))
    block = @scraper.extract_blocks(html).first
    paper = @scraper.extract_paper_details(block)

    assert_equal ['CDU'], paper[:originators][:parties]
  end

  test 'extract originators from major paper with a four names and two parties' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/nw/detail_7576.html')))
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
end
