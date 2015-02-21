require 'test_helper'

class BerlinAghScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @scraper = BerlinAghScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/berlin_agh_scraper_overview.html')))
  end

  def paper_from_fixture(reference)
    html = Nokogiri::HTML(File.read(Rails.root.join("test/fixtures/berlin_agh_scraper_overview_#{reference}.html")))
    body = @scraper.extract_body(html)
    seperator = @scraper.extract_seperators(body).first
    @scraper.extract_paper(seperator)
  end

  test 'extract seperators from search result page' do
    body = @scraper.extract_body(@html)
    seperators = @scraper.extract_seperators(body)
    # test fixture contains only 58 papers
    assert_equal 58, seperators.size
  end

  test 'extract title from next row' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    title = @scraper.extract_title(seperator)
    assert_equal 'Bilanzkosmetik bei der Flughafengesellschaft? (II)', title
  end

  test 'extract data cell from next rows' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    # using * for whitespace:
    html = <<-END.gsub(/^ {6}/, '').gsub(/\*/, ' ')

      *<!--XX-->Martin*Delius*(Piraten)<br>
      ************
      <a*href="/starweb/adis/citat/VT/17/SchrAnfr/s17-15458.pdf">Drucksache*17/15458</a>
      *vom*03.02.2015
      <br><br>
      *<u>Folge**1</u><br>
      Antwort*<!--XX--><br>
      ************
      RBm<br>
      ************
      <a*href="/starweb/adis/citat/VT/17/SchrAnfr/s17-15458.pdf">Drucksache*17/15458</a>
      *vom*10.02.2015
    END
    assert_equal html, data_cell.inner_html
  end

  test 'extract paper link element from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    link = @scraper.extract_link(data_cell)
    assert_equal '<a href="/starweb/adis/citat/VT/17/SchrAnfr/s17-15458.pdf">Drucksache 17/15458</a>', link.to_html
  end

  test 'extract names from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    names = @scraper.extract_names(data_cell)
    assert_equal 'Martin Delius (Piraten)', names
  end

  test 'extract ministry line from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    ministry_line = @scraper.extract_ministry_line(data_cell)
    assert_equal 'RBm', ministry_line
  end

  test 'extract published_at from data cell' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    data_cell = @scraper.extract_data_cell(seperator)
    date = @scraper.extract_date(data_cell)
    assert_equal '10.02.2015', date
  end

  test 'try to never get empty originators' do
    body = @scraper.extract_body(@html)
    @scraper.extract_seperators(body).each do |seperator|
      data_cell = @scraper.extract_data_cell(seperator)
      link = @scraper.extract_link(data_cell)
      full_reference = @scraper.extract_full_reference(link)
      assert_not @scraper.extract_names(data_cell).blank?, "[#{full_reference}] originators blank"
    end
  end

  test 'extract complete paper' do
    body = @scraper.extract_body(@html)
    seperator = @scraper.extract_seperators(body).first
    paper = @scraper.extract_paper(seperator)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/15458',
        reference: '15458',
        title: 'Bilanzkosmetik bei der Flughafengesellschaft? (II)',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-15458.pdf',
        published_at: Date.parse('10.02.2015'),
        originators: { people: ['Martin Delius'], parties: ['Piraten'] },
        answerers: { ministries: ['RBm'] }
      }, paper)
  end

  test 'support more documents like in 17/13584' do
    paper = paper_from_fixture('13584')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/13584',
        reference: '13584',
        title: 'Wohnungsmarkt Berlin und Brandenburg',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-13548.pdf',
        published_at: Date.parse('23.04.2014'),
        originators: { people: ['Andreas Otto'], parties: ['Grüne'] },
        answerers: { ministries: ['SenStadtUm'] }
      }, paper)
  end

  test 'support two ministries like in 17/13566' do
    paper = paper_from_fixture('13566')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/13566',
        reference: '13566',
        title: 'Denkzeichen - Kohlenhandlung Julius und Annedore Leber',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-13566.pdf',
        published_at: Date.parse('11.04.2014'),
        originators: { people: ['Markus Klaer'], parties: ['CDU'] },
        answerers: { ministries: ['RBm', 'Skzl'] }
      }, paper)
  end

  test 'support missing answer pdf like in 17/13768' do
    paper = paper_from_fixture('13768')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/13768',
        reference: '13768',
        title: 'Studierende brauchen Wohnheimplätze und keine Luftschlösser',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-13768.pdf',
        published_at: Date.parse('22.05.2014'),
        originators: { people: ['Dr. Wolfgang Albers'], parties: ['Die Linke'] },
        answerers: { ministries: ['SenBildJugWiss'] }
      }, paper)
  end

  test 'support missing answer pdf and date like in 17/13307' do
    paper = paper_from_fixture('13307')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/13307',
        reference: '13307',
        title: 'Berliner Grillflächen nicht weiter reduzieren',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-13307.pdf',
        published_at: Date.parse('28.02.2014'),
        originators: { people: ['Stephan Lenz'], parties: ['CDU'] },
        answerers: { ministries: ['SenStadtUm'] }
      }, paper)
  end

  test 'support newline in title like in 17/15272' do
    paper = paper_from_fixture('15272')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/15272',
        reference: '15272',
        title: 'Umsetzung des Partizipations- & Integrationsgesetzes (V) Bezirkliche Integrationsausschüsse',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-15272.pdf',
        published_at: Date.parse('30.01.2015'),
        originators: { people: ['Hakan Tas'], parties: ['Die Linke'] },
        answerers: { ministries: ['SenArbIntFrau'] }
      }, paper)
  end

  test 'support newline in title like in 17/15093' do
    paper = paper_from_fixture('15093')

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/15093',
        reference: '15093',
        title: 'Wie ist der aktuelle Stand der Lehrkräfteausstattung in Lichtenberg?',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-15093.pdf',
        published_at: Date.parse('03.12.2014'),
        originators: { people: ['Martin Delius'], parties: ['Piraten'] },
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
        full_reference: '17/15324',
        reference: '15324',
        title: 'Bürgerbeteiligung in Berlins Stadtplanung (2014)',
        url: 'http://pardok.parlament-berlin.de/starweb/adis/citat/VT/17/SchrAnfr/s17-15324.pdf',
        published_at: Date.parse('06.02.2015'),
        originators: { people: ['Stefan Evers'], parties: ['CDU'] },
        answerers: { ministries: ['SenStadtUm'] }
      }, paper)
  end
end