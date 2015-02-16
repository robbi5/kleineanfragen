require 'test_helper'

class BerlinAghScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BerlinAghScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/berlin_agh_scraper_overview.html')))
  end

  test 'extract seperators from search result page' do
    body = @scraper.extract_body(@html)
    seperators = @scraper.extract_seperators(body)
    assert_equal 1000, seperators.size
  end

  test 'extract title from next row' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    title = @scraper.extract_title(seperator)
    assert_equal 'Abschaffung der Indologie und Kunstgeschichte Südasiens?', title
  end

  test 'extract data cell from next rows' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    # using * for whitespace:
    html = <<-END.gsub(/^ {6}/, '').gsub(/\*/, ' ')

      *<!--XX-->Stefan*Schlede*(CDU)<br>
      ************
      <a*href="/starweb/adis/citat/VT/17/SchrAnfr/s17-14217.pdf">Drucksache*17/14217</a>
      *vom*14.07.2014
      <br><br>
      *<u>Folge**1</u><br>
      Antwort*<!--XX--><br>
      ************
      SenBildJugWiss<br>
      ************
      <a*href="/starweb/adis/citat/VT/17/SchrAnfr/s17-14217.pdf">Drucksache*17/14217</a>
      *vom*17.07.2014
    END
    assert_equal html, data_cell.inner_html
  end

  test 'extract paper link element from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    link = @scraper.extract_link(data_cell)
    assert_equal '<a href="/starweb/adis/citat/VT/17/SchrAnfr/s17-14217.pdf">Drucksache 17/14217</a>', link.to_html
  end

  test 'extract names from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    names = @scraper.extract_names(data_cell)
    assert_equal 'Stefan Schlede (CDU)', names
  end

  test 'extract ministry line from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    ministry_line = @scraper.extract_ministry_line(data_cell)
    assert_equal 'SenBildJugWiss', ministry_line
  end

  test 'extract published_at from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    date = @scraper.extract_date(data_cell)
    assert_equal '17.07.2014', date
  end

  test 'extract complete paper' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    paper = @scraper.extract_paper(seperator)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/14217',
        reference: '14217',
        title: 'Abschaffung der Indologie und Kunstgeschichte Südasiens?',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-14217.pdf',
        published_at: Date.parse('17.07.2014'),
        originators: { people: ['Stefan Schlede'], parties: ['CDU'] },
        answerers: { ministries: ['SenBildJugWiss'] }
      }, paper)
  end

  test 'extract last complete paper' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).last
    paper = @scraper.extract_paper(seperator)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/13155',
        reference: '13155',
        title: 'Expertise Jugendberufshilfe',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-13155.pdf',
        published_at: Date.parse('19.02.2014'),
        originators: { people: ['Marianne Burkert-Eulitz'], parties: ['Grüne'] },
        answerers: { ministries: ['SenBildJugWiss'] }
      }, paper)
  end
end