require 'test_helper'

class HessenTest < ActiveSupport::TestCase
  def setup
    @scraper = HessenScraper
    @overview = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_overview.html')))
    @detail_minor = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_detail_minor.html')))
    @detail_major = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_detail_major.html')))
    @search = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_search.html')))
    @blocks = @scraper.extract_blocks @overview
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
    @detail_block_minor = @scraper.extract_detail_block(@detail_minor)
    text = @scraper.extract_originator_text(@detail_block_minor)
    assert_equal(
      {
        people: [
          'Marius Weiß', 'Norbert Schmitt', 'Wolfgang Decker',
          'Kerstin Geis', 'Brigitte Hofmeyer', 'Gerald Kummer',
          'Angelika Löber', 'Torsten Warnecke'
        ],
        parties: ['SPD']
      }, @scraper.extract_originators(text))

    text = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
      GrAnfr             Waschke, Sabine, SPD
      16.10.2014 Drs 19/1030
      Antw 09.02.2015 Drs 19/1578
      PlPr 19/38  05.03.2015
      von Tagesordnung abgesetzt
      Ausschussberatung:
      EUA 19/13  14.04.2015 (ö)
    END
    assert_equal({ people: ['Sabine Waschke'], parties: ['SPD'] }, @scraper.extract_originators(text))
  end

  test 'extract originators from text' do
    text = "KlAnfr             Greilich, Wolfgang, FDP\n  18.11.2014 und Antw 08.01.2015 Drs 19/1128"
    assert_equal({ people: ['Wolfgang Greilich'], parties: ['FDP'] }, @scraper.extract_originators(text))
  end

  test 'get result from search' do
    assert_equal true, @scraper.extract_result_from_search(@search).content.include?('Europäische Förderprogramme ')
  end

  test 'get reference from search result' do
    @search_result = @scraper.extract_result_from_search(@search)
    assert_equal ['19', '1030'], @scraper.extract_reference(@search_result)
  end

  test 'extract_interpellation_type from search result' do
    assert_equal Paper::DOCTYPE_MINOR_INTERPELLATION, @scraper.extract_interpellation_type(@blocks.first)
  end

  test 'extract complex answer line' do
    text = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
      Europäische Förderprogramme
      GrAnfr             Waschke, Sabine, SPD; Franz, Dieter, SPD; Geis,
                         Kerstin, SPD; Grüger, Stephan, SPD; Kummer,
                         Gerald, SPD; Quanz, Lothar, SPD; Fraktion der SPD
      16.10.2014 Drs 19/1030
      Antw 09.02.2015 Drs 19/1578
      PlPr 19/38  05.03.2015
      von Tagesordnung abgesetzt
      Ausschussberatung:
      EUA 19/13  14.04.2015 (ö)
    END
    assert_equal 'Antw 09.02.2015 Drs 19/1578', @scraper.extract_answer_line(text)
  end

  test 'extract simple answer line' do
    text = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
      Studium Generale
      KlAnfr             Sommer, Daniela, Dr., SPD
      24.03.2015 und Antw 29.04.2015 Drs 19/1774
    END
    assert_equal '24.03.2015 und Antw 29.04.2015 Drs 19/1774', @scraper.extract_answer_line(text)
  end

  test 'extract nil answer line' do
    assert_nil @scraper.extract_answer_line('')
  end

  test 'extract fraktion like in 1585' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hessen_detail_1585.html')))
    block = @scraper.extract_detail_block(html)
    text = @scraper.extract_originator_text(block)
    assert_equal(
      {
        people: [],
        parties: ['DIE LINKE']
      }, @scraper.extract_originators(text))
  end
end