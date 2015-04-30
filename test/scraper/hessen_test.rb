require 'test_helper'

class HessenTest < ActiveSupport::TestCase
  def setup
    @scraper = HessenScraper
    @overview = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_overview.html')))
    @detail_minor = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_detail_minor.html')))
    @detail_major = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_detail_major.html')))
    @search = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_search.html')))
    @blocks = @scraper.extract_blocks @overview
    @detail_block_minor = @scraper.extract_detail_block(@detail_minor)
    @detail_block_major = @scraper.extract_detail_block(@detail_major)
    @search_result = @scraper.extract_result_from_search(@search)
  end

  test 'get overview blocks' do
    blocks = @scraper.extract_blocks @overview
    assert_equal 634, blocks.length
  end

  test 'get detail block' do
    assert_equal true, @scraper.extract_detail_block(@detail_minor).content.include?('und Antw 17.02.2015 Drs')
    assert_equal true, @scraper.extract_detail_block(@detail_major).content.include?('23.02.2015 Drs 19/1632')
  end

  test 'get reference from block' do
    assert_equal ['19', '1774'], @scraper.extract_reference(@blocks.first)
  end

  test 'extract_interpellation_type' do
    assert_equal Paper::DOCTYPE_MINOR_INTERPELLATION, @scraper.extract_interpellation_type(@blocks.first)
  end

  test 'extract title' do
    assert_equal 'Studium Generale', @scraper.extract_title(@blocks.first)
  end

  test 'extract originators' do
    text = @scraper.extract_originator_text(@detail_block_minor)
    assert_equal({people: ["Marius Weiß", "Norbert Schmitt", "Wolfgang Decker", "Kerstin Geis", "Brigitte Hofmeyer", "Gerald Kummer", "Angelika Löber", "Torsten Warnecke"], parties: ["SPD"]}, @scraper.extract_originators(text))

    text = "GrAnfr             Waschke, Sabine, SPD
  16.10.2014 Drs 19/1030
  Antw 09.02.2015 Drs 19/1578
  PlPr 19/38  05.03.2015
  von Tagesordnung abgesetzt
  Ausschussberatung:
  EUA 19/13  14.04.2015 (ö)"
    assert_equal({people: ["Sabine Waschke"], parties: ["SPD"]}, @scraper.extract_originators(text))
  end

  test 'extract originators from text' do
    text = "KlAnfr             Greilich, Wolfgang, FDP
  18.11.2014 und Antw 08.01.2015 Drs 19/1128"
    assert_equal({people: ["Wolfgang Greilich"], parties: ["FDP"]}, @scraper.extract_originators(text))
  end

  test 'get result from search' do
    assert_equal true, @scraper.extract_result_from_search(@search).content.include?('Europäische Förderprogramme ')
  end

  test 'get reference from search result' do
    assert_equal ['19', '1030'], @scraper.extract_reference(@search_result)
  end

  test 'extract_interpellation_type from search result' do
    assert_equal Paper::DOCTYPE_MINOR_INTERPELLATION, @scraper.extract_interpellation_type(@blocks.first)
  end

  test 'extract answer line' do
    text = "Europäische Förderprogramme
  GrAnfr             Waschke, Sabine, SPD; Franz, Dieter, SPD; Geis,
                     Kerstin, SPD; Grüger, Stephan, SPD; Kummer,
                     Gerald, SPD; Quanz, Lothar, SPD; Fraktion der SPD
  16.10.2014 Drs 19/1030
  Antw 09.02.2015 Drs 19/1578
  PlPr 19/38  05.03.2015
  von Tagesordnung abgesetzt
  Ausschussberatung:
  EUA 19/13  14.04.2015 (ö)

    "
    assert_equal 'Antw 09.02.2015 Drs 19/1578', @scraper.extraxct_answer_line(text)
    text = "Studium Generale
  KlAnfr             Sommer, Daniela, Dr., SPD
  24.03.2015 und Antw 29.04.2015 Drs 19/1774
            "
    assert_equal '24.03.2015 und Antw 29.04.2015 Drs 19/1774', @scraper.extraxct_answer_line(text)
    assert_equal true, @scraper.extraxct_answer_line("").nil?
  end
end