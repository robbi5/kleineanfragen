require 'test_helper'

class SchleswigholsteinLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = SchleswigHolsteinLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/schleswigholstein_landtag_scraper_overview.html')
                           ).force_encoding("WINDOWS-1252"))
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
    assert_equal "Kinderschutz durch Therapie pädophil veranlagter Menschen", @scraper.extract_title(@blocks[0])
  end

  test 'is answered' do
    assert_equal true, @scraper.answer?(@blocks[0])
    assert_equal false, @scraper.answer?(@blocks[1])
  end

  test 'get ministries' do
    meta = @scraper.extract_meta(@blocks[0])
    assert_equal ["Minister/in für Soziales, Gesundheit, Wissenschaft und Gleichstellung"], meta[:ministries]
    meta = @scraper.extract_meta(@blocks[1])
    assert_equal [], meta[:ministries]
  end

  test 'get originators' do
    meta = @scraper.extract_meta(@blocks[0])
    assert_equal ["Dr. Patrick Breyer", "Wolfgang Dudda"], meta[:originators][:people]
    meta = @scraper.extract_meta(@blocks[1])
    assert_equal ["Dr. Patrick Breyer"], meta[:originators][:people]
  end

  test 'get parties' do
    meta = @scraper.extract_meta(@blocks[0])
    assert_equal ["PIRATEN"], meta[:originators][:parties]

    meta = @scraper.extract_meta(@blocks[1])
    assert_equal ["PIRATEN"], meta[:originators][:parties]
  end

  test 'get date' do
    meta = @scraper.extract_meta(@blocks[8])
    assert_equal Date.parse('2015-12-14'), meta[:published_date]

    meta = @scraper.extract_meta(@blocks[7])
    assert_equal nil, meta[:published_date]
  end

  test 'get full reference' do
    assert_equal '18/2540', @scraper.extract_full_reference(@blocks[0])
    assert_equal '18/2915', @scraper.extract_full_reference(@blocks[1])
  end

  test 'get pdf url' do
    assert_equal 'http://www.landtag.ltsh.de/infothek/wahl18/drucks/2500/drucksache-18-2540.pdf', @scraper.extract_url(@blocks[0])
    assert_equal 'http://www.landtag.ltsh.de/infothek/wahl18/drucks/2900/drucksache-18-2915.pdf', @scraper.extract_url(@blocks[1])
  end

end