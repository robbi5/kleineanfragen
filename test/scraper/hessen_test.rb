require 'test_helper'

class HessenTest < ActiveSupport::TestCase
  def setup
    @scraper = HessenScraper
    @overview = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/overview.html')))
    @detail_minor = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_minor.html')))
    @detail_major = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_major.html')))
    @search = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/search.html')))
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
    assert_equal '19/1774', @scraper.extract_reference(@blocks.first)
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
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_1585.html')))
    block = @scraper.extract_detail_block(html)
    text = @scraper.extract_originator_text(block)
    assert_equal(
      {
        people: [],
        parties: ['DIE LINKE']
      }, @scraper.extract_originators(text))
  end

  test 'extract fraktion from a big block like in 382' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_382.html')))
    block = @scraper.extract_detail_block(html)
    text = @scraper.extract_originator_text(block)
    assert_equal(
      {
        people: [],
        parties: ['DIE LINKE']
      }, @scraper.extract_originators(text))
  end

  test 'extract whole paper from detail page like 19/1017' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_1017.html')))
    block = @scraper.extract_detail_block(html)
    paper = @scraper.extract_detail_paper(block)

    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/1829',
        reference: '1829',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Evaluation der Lehrerbildung in Hessen',
        published_at: Date.parse('2015-04-15'),
        originators: {
          people: ['Christoph Degen', 'Kerstin Geis', 'Karin Hartmann', 'Brigitte Hofmeyer', 'Gerhard Merz', 'Lothar Quanz', 'Turgut Yüksel'],
          parties: ['SPD']
        },
        is_answer: nil
      }, paper)
  end

  test 'extract whole paper from detail page like 19/1616' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_19_1616.html')))
    block = @scraper.extract_detail_block(html)
    paper = @scraper.extract_detail_paper(block)
    assert_equal Date.parse('2015-04-13'), paper[:published_at]
  end

  test 'extract whole paper from detail page like 19/1615' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/he/detail_19_1615.html')))
    block = @scraper.extract_detail_block(html)
    paper = @scraper.extract_detail_paper(block)
    assert_equal Date.parse('2015-04-02'), paper[:published_at]
  end
end