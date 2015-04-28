require 'test_helper'

class SachsenAnhaltLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sachsen_anhalt_landtag_scraper_overview.html')))
    @scraper = SachsenAnhaltLandtagScraper
  end

  test 'extract blocks from search result page' do
    blocks = @scraper.extract_blocks(@html)
    assert_equal 2031, blocks.size
  end

  test 'extract meta from result meta line of a minor interpellation' do
    line = 'Bezug: Kleine Anfrage und Antwort Eva Feußner (CDU) und Antwort Ministerium für Wissenschaft und Wirtschaft 24.07.2014 Drucksache 6/3311 (KA 6/8388) (3 S.)'
    meta = @scraper.extract_meta(line)
    assert_equal(
      {
        full_reference: '6/3311',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        originators: 'Eva Feußner (CDU)',
        answerers: 'Ministerium für Wissenschaft und Wirtschaft',
        published_at: '24.07.2014',
        is_answer: true
      }, meta)
  end

  test 'extract meta from result meta line of a answer to a major interpellation' do
    line = 'Bezug: Antwort Landesregierung 09.02.2015 Drucksache 6/3801 (79 S.)'
    meta = @scraper.extract_meta(line)
    assert_equal(
      {
        full_reference: '6/3801',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        originators: nil,
        answerers: 'Landesregierung',
        published_at: '09.02.2015',
        is_answer: true
      }, meta)
  end

  test 'extract meta from result meta line of a major interpellation' do
    line = 'Große Anfrage SPD 07.11.2014 Drucksache 6/3591 (9 S.)'
    meta = @scraper.extract_meta(line)
    assert_equal(
      {
        full_reference: '6/3591',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        originators: 'SPD',
        answerers: nil,
        published_at: '07.11.2014',
        is_answer: false
      }, meta)
  end

  test 'paper without answer throws exception' do
    block = @scraper.extract_blocks(@html).first
    assert_raises RuntimeError do
      @scraper.extract_paper(block)
    end
  end

  test 'extract complete paper' do
    block = @scraper.extract_blocks(@html)[1]
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/4015',
        reference: '4015',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Beobachtungsobjekte des Verfassungsschutzes in Sachsen-Anhalt',
        url: 'http://padoka.landtag.sachsen-anhalt.de/files/drs/wp6/drs/d4015gak.pdf',
        published_at: Date.parse('2015-04-24'),
        originators: {
          people: ['Sebastian Striegel'],
          parties: ['BÜNDNIS 90/DIE GRÜNEN']
        },
        is_answer: true,
        answerers: {
          ministries: ['Ministerium für Inneres und Sport']
        }
      }, paper)
  end
end