require 'test_helper'

class SchleswigHolsteinLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = SchleswigHolsteinLandtagScraper
    @html = Nokogiri::HTML(
      File.read(
        Rails.root.join('test/fixtures/schleswigholstein_landtag_scraper_overview.html')
      ).force_encoding('WINDOWS-1252')
    )
    @table = @scraper.extract_table @html
    @blocks = @scraper.extract_blocks @table
  end

  test 'extract table from resultpage' do
    assert_equal 2679, @table.children.length
  end

  test 'get blocks from table' do
    @table = @scraper.extract_table @html
    assert_equal 1338, @blocks.length
  end

  test 'get title from block' do
    assert_equal 'Planungskapazitäten für den NOK und die Rader Hochbrücke', @scraper.extract_title(@blocks[15])
  end

  test 'is answered' do
    assert_equal false, @scraper.answer?(@blocks[1])
    assert_equal true, @scraper.answer?(@blocks[15])
    # not really answered, because date is missing.
    assert_equal true, @scraper.answer?(@blocks[0])
  end

  test 'get meta is nil if date is undefined' do
    assert_nil @scraper.extract_meta(@blocks[0])
  end

  test 'get ministries' do
    meta = @scraper.extract_meta(@blocks[15])
    assert_equal ['Minister/in für Wirtschaft, Arbeit, Verkehr und Technologie'], meta[:ministries]
  end

  test 'get originators' do
    meta = @scraper.extract_meta(@blocks[15])
    assert_equal ['Hans-Jörn Arp', 'Johannes Callsen'], meta[:originators][:people]
    assert_equal ['CDU'], meta[:originators][:parties]
  end

  test 'get date' do
    meta = @scraper.extract_meta(@blocks[15])
    assert_equal Date.parse('2214-12-14'), meta[:published_at]
  end

  test 'get full reference' do
    assert_equal '18/2537', @scraper.extract_full_reference(@blocks[15])
  end

  test 'get pdf url' do
    assert_equal 'http://www.landtag.ltsh.de/infothek/wahl18/drucks/2500/drucksache-18-2537.pdf', @scraper.extract_url(@blocks[15])
    assert_equal 'http://www.landtag.ltsh.de/infothek/wahl18/drucks/2500/drucksache-18-2540.pdf', @scraper.extract_url(@blocks[0])
  end

  test 'get major paper' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/schleswigholstein_landtag_scraper_major.html')
                          ).force_encoding("WINDOWS-1252"))
    table = @scraper.extract_table html
    blocks = @scraper.extract_blocks table
    paper = @scraper.extract_major_paper blocks[0]
    assert_equal(
      {
        legislative_term: '17',
      full_reference: '17/2295',
      reference: '2295',
      doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
      title: 'Kinder und Jugendliche mit Migrationshintergrund im Bildungssystem Schleswig-Holsteins',
      url: 'http://www.landtag.ltsh.de/infothek/wahl17/drucks/2200/drucksache-17-2295.pdf',
      published_at: Date.parse('15.02.2012'),
      is_answer: true,
      answerers: { ministries: ["Landesregierung"] }
    }, paper)
  end

  test 'block is minor or major' do
    assert_equal false, @scraper.major?(@blocks[0])

    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/schleswigholstein_landtag_scraper_major.html')
                          ).force_encoding("WINDOWS-1252"))
    table = @scraper.extract_table html
    block = @scraper.extract_blocks table
    assert_equal true, @scraper.major?(block)

  end

  test 'update details' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/schleswigholstein_landtag_scraper_major_detail.html')
                          ).force_encoding("WINDOWS-1252"))
    block = @scraper.extract_detail_block(html)
    assert_equal false, block.nil?
    line = @scraper.extract_originator_line block
    assert_equal 'Anke Erdmann (BÜNDNIS 90/DIE GRÜNEN) 07.10.2011 Drucksache', line
    originators = NamePartyExtractor.new(line).extract

    assert_equal({
                   :people=>["Anke Erdmann"],
                   :parties=>["BÜNDNIS 90/DIE GRÜNEN"]
                 }, originators)
    paper = @scraper.update_major_details({}, html)
    assert_equal({originators: {:people=>["Anke Erdmann"],:parties=>["BÜNDNIS 90/DIE GRÜNEN"]}}, paper)
  end
end