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
        url: 'https://www.landtag.nrw.de/portal/WWW/dokumentenarchiv/Dokument?Id=MMD16/8512%7C1%7C0',
        published_at: Date.parse('2015-04-24'),
        originators: nil,
        is_answer: true,
        answerers: { ministries: ['MGEPA'] },
        source_url: 'https://www.landtag.nrw.de/portal/WWW/Webmaster/GB_II/II.2/Suche/Landtagsdokumentation_ALWP/Suchergebnisse_Ladok.jsp?' +
          'order=native%28%27DOKDATUM%281%29%2FDescend+%2C+VA%281%29%2FDescend+%27%29&fm=&wp=16' +
          '&w=native%28%27%28NUMMER+phrase+like+%27%278512%27%27%29+and+%28DOKUMENTART+phrase+like+%27%27DRUCKSACHE%27%27%29+and+%28DOKUMENTTYP+phrase+like+%27%27ANTWORT%27%27%29%27%29'
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
        url: 'https://www.landtag.nrw.de/portal/WWW/dokumentenarchiv/Dokument?Id=MMD16/8774%7C1%7C0',
        published_at: Date.parse('2015-05-27'),
        originators: nil,
        is_answer: true,
        answerers: { ministries: ['MSW'] },
        source_url: 'https://www.landtag.nrw.de/portal/WWW/Webmaster/GB_II/II.2/Suche/Landtagsdokumentation_ALWP/Suchergebnisse_Ladok.jsp?' +
          'order=native%28%27DOKDATUM%281%29%2FDescend+%2C+VA%281%29%2FDescend+%27%29&fm=&wp=16' +
          '&w=native%28%27%28NUMMER+phrase+like+%27%278774%27%27%29+and+%28DOKUMENTART+phrase+like+%27%27DRUCKSACHE%27%27%29+and+%28DOKUMENTTYP+phrase+like+%27%27ANTWORT%27%27%29%27%29'
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
