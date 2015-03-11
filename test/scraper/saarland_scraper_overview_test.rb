require 'test_helper'

class SaarlandScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = SaarlandScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/saarland_scraper_overview.html')))
  end

  entry = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/saarland_scraper_single_row.html')))
  invalid_entry = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/saarland_scraper_single_invalid_row.html')))

  test 'read table from resultpage' do
    entries = @scraper.extract_entries(@html)
    assert_equal 30, entries.size
  end

  test 'create paper from table row' do
    paper = @scraper.extract_paper(entry)
    assert_equal(
      {
        legislative_term: '15',
        full_reference: '15/1200',
        reference: '1200',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Abordnungen an Ministerien im Saarland',
        url: 'http://www.landtag-saar.de/Dokumente/Drucksachen/Aw15_1200.pdf',
        published_at: Date.parse('2015-01-12'),
        originators: {
          parties: ['PIRATEN']
        },
        is_answer: true,
        answerers: { ministries: ['Landesregierung'] }
      }, paper)
  end

  test 'get link in table row' do
    assert_equal 'http://www.landtag-saar.de/Dokumente/Drucksachen/Aw15_1200.pdf', @scraper.extract_doc_link(entry)
  end

  test 'get full reference from href' do
    href = 'http://www.landtag-saar.de/Dokumente/Drucksachen/Aw15_1200.pdf'
    assert_equal '15/1200', @scraper.extract_full_reference_from_href(href)
  end

  test 'get date from entry' do
    assert_equal Date.parse('2015-01-12'), @scraper.extract_date(entry)
  end

  test 'get title from entry' do
    assert_equal 'Abordnungen an Ministerien im Saarland', @scraper.extract_title(entry)
  end

  test 'get parties' do
    persons_text = 'Neyses (PIRATEN)'
    parties = @scraper.extract_parties(persons_text)
    assert_equal(
      {
        parties: ['PIRATEN']
      }, parties)
  end

  test 'get originator text for entry' do
    assert_equal 'Neyses (PIRATEN)', @scraper.extract_originator_text(entry)
  end

  test 'is answer' do
    href = 'http://www.landtag-saar.de/Dokumente/Drucksachen/Aw15_1200.pdf'
    assert @scraper.extract_is_answer(href)
    href = 'http://www.landtag-saar.de/Dokumente/Drucksachen/So15_1200.pdf'
    assert_not @scraper.extract_is_answer(href)
  end

  test 'ignore invalid doctypes' do
    assert_equal nil, @scraper.extract_paper(invalid_entry)
    assert_not_equal nil, @scraper.extract_paper(entry)
  end
end