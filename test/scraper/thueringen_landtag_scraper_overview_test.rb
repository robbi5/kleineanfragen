require 'test_helper'

class ThueringenLandtagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = ThueringenLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/thueringen_landtag_scraper_overview.html')))
  end

  test 'get search results from resultpage' do
    results = @scraper.extract_results(@html)
    assert_equal 10, results.size
  end

  test 'get next_row from from title_el' do
    results = @scraper.extract_results(@html)
    next_row = @scraper.extract_next_row(results.first)
    html = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')

                          <td headers=\"result-nummer\">6/517</td>
                          <td headers=\"result-typ\"> Antwort auf Kleine Anfrage</td>
                          <td headers=\"result-datum\">21.04.2015</td>
                      
    END
    assert_equal html, next_row.inner_html
  end

  test 'get title from title_el' do
    results = @scraper.extract_results(@html)
    title_el = results.first
    title = @scraper.extract_title_text(title_el)
    assert_equal 'Fortsetzung des Seminar-Angebots "Lernort Landtag" durch die Landeszentrale für politische Bildung', title
  end

  test 'get full_reference from next_row' do
    results = @scraper.extract_results(@html)
    next_row = @scraper.extract_next_row(results.first)
    full_reference = @scraper.extract_full_reference(next_row)
    assert_equal '6/517', full_reference
  end

  test 'get reference and legislative term from full_reference' do
    results = @scraper.extract_results(@html)
    next_row = @scraper.extract_next_row(results.first)
    full_reference = @scraper.extract_full_reference(next_row)
    legislative_term, reference = @scraper.extract_reference(full_reference)
    assert_equal '6', legislative_term
    assert_equal '517', reference
  end

  test 'get path from title_el' do
    results = @scraper.extract_results(@html)
    title_el = results.first
    path = @scraper.extract_path(title_el)
    assert_equal '/ParlDok/dokument/54728/fortsetzung-des-seminar-angebots-lernort-landtag-durch-die-landeszentrale-f%c3%bcr-politische-bildung.pdf', path
  end

  test 'get url from path' do
    results = @scraper.extract_results(@html)
    title_el = results.first
    path = @scraper.extract_path(title_el)
    url = @scraper.extract_url(path)
    assert_equal 'http://www.parldok.thueringen.de/ParlDok/dokument/54728/fortsetzung-des-seminar-angebots-lernort-landtag-durch-die-landeszentrale-f%C3%BCr-politische-bildung.pdf', url
  end

  test 'extract doctype_el from next_row' do
    results = @scraper.extract_results(@html)
    next_row = @scraper.extract_next_row(results.first)
    doctype_el = @scraper.extract_doctype_el(next_row)
    html = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
 Antwort auf Kleine Anfrage
    END
    assert_equal html, doctype_el.inner_html
  end

  test 'extract meta from next_row' do
    results = @scraper.extract_results(@html)
    next_row = @scraper.extract_next_row(results.first)
    meta = @scraper.extract_meta(next_row)
    assert_equal 'minor', meta[:doctype]
    assert_equal 'Landesregierung', meta[:answerers]
    assert_equal '21.04.2015', meta[:published_at]
  end

  test 'extract paper' do
    results = @scraper.extract_results(@html)
    paper = @scraper.extract_paper(results.first)
    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/517',
        reference: '517',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Fortsetzung des Seminar-Angebots "Lernort Landtag" durch die Landeszentrale für politische Bildung',
        url: 'http://www.parldok.thueringen.de/ParlDok/dokument/54728/fortsetzung-des-seminar-angebots-lernort-landtag-durch-die-landeszentrale-f%C3%BCr-politische-bildung.pdf',
        published_at: Date.parse('2015-04-21'),
        answerers: {
          ministries: ['Landesregierung']
        }
      }, paper)
  end
end