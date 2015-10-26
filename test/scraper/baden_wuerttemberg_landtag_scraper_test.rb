require 'test_helper'

class BadenWuerttembergLandtagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BadenWuerttembergLandtagScraper
    @search_url = 'http://www.landtag-bw.de/cms/render/live/de/sites/LTBW/home/dokumente/die-initiativen/gesamtverzeichnis/contentBoxes/suche-initiative.html?'
    @legislative_page = Mechanize.new.get('file://' + Rails.root.join('test/fixtures/baden_wuerttemberg_legislative_term_page.html').to_s)
    @result_page = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/baden_wuerttemberg_result_page.html')))
    @detail_page = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/baden_wuerttemberg_detail_page.html')))
  end

  test 'get legislative start and end date from url' do
    legislative = @scraper::Overview.new(15)
    actual = legislative.extract_legislative_dates(@legislative_page)
    expected = [Date.parse('01.05.2011'), Date.parse('30.04.2016')]
    assert_equal(expected, actual)
  end

  test 'get all months as array' do
    date1 = Date.parse('2014-01-01')
    date2 = Date.parse('2015-02-02')
    expected = [
      [2014, 1],
      [2014, 2],
      [2014, 3],
      [2014, 4],
      [2014, 5],
      [2014, 6],
      [2014, 7],
      [2014, 8],
      [2014, 9],
      [2014, 10],
      [2014, 11],
      [2014, 12],
      [2015, 1],
      [2015, 2]
    ]
    actual = @scraper::Overview.get_legislative_period(date1, date2)
    assert_equal(expected, actual)
  end

  test 'build single urls for legislative period' do
    type = 'KA'
    legislative_period = [
      [2013, 11],
      [2013, 12],
      [2014, 1],
      [2014, 2]
    ]
    actual = @scraper::Overview.get_search_urls(@search_url, legislative_period, type)
    expected = [
      @search_url + 'searchInitiativeType=KA&searchYear=2014&searchMonth=02',
      @search_url + 'searchInitiativeType=KA&searchYear=2014&searchMonth=01',
      @search_url + 'searchInitiativeType=KA&searchYear=2013&searchMonth=12',
      @search_url + 'searchInitiativeType=KA&searchYear=2013&searchMonth=11'
    ]
    assert_equal(expected, actual)
  end

  test 'extract result div from resultslist' do
    actual = @scraper.extract_result_blocks(@result_page).size
    expected = 40
    assert_equal(expected, actual)
  end

  test 'extract meta from overview div' do
    div = @scraper.extract_result_blocks(@result_page)[0]
    actual = @scraper.extract_overview_meta(div)
    assert_equal(
      {
        full_reference: '15/6432',
        published_at: Date.parse('2015-01-29'),
        doctype: 'Kleine Anfrage',
        originator_party: 'SPD'
      }, actual)
  end

  test 'extract title from result div' do
    div = @scraper.extract_result_blocks(@result_page)[0]
    actual = @scraper.extract_title(div)
    expected = 'Barrierefreier Ausbau der Bahnhöfe auf der Hauptstrecke Stuttgart-Ulm im Landkreis Göppingen zwischen Reichenbach/Fils und Eislingen/Fils'
    assert_equal(expected, actual)
  end

  test 'build detail url for answer-chek from full reference' do
    legislative_term = '15'
    reference = '6432'
    actual = @scraper.build_detail_url(legislative_term, reference)
    expected = 'http://www.statistik-bw.de/OPAL/Ergebnis.asp?WP=15&DRSNR=6432'
    assert_equal(expected, actual)
  end

  test 'get detail link from detail page' do
    actual = @scraper.get_detail_link(@detail_page).text.lstrip
    expected = 'KlAnfr Peter Hofelich SPD 29.01.2015 und Antw MVI Drs 15/6432'
    assert_equal(expected, actual)
  end

  test 'check document for answer' do
    link = @scraper.get_detail_link(@detail_page)
    is_answer = @scraper.link_is_answer?(link)
    assert is_answer, 'should be an answer'
  end

  test 'extract meta information from detail link' do
    link = @scraper.get_detail_link(@detail_page)
    actual = @scraper.extract_meta(link.text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2015-01-29'),
      originators: { people: ['Peter Hofelich'], parties: ['SPD'] },
      answerers: { ministries: ['MVI'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from long detail link' do
    text = 'KlAnfr Arnulf Freiherr von Eyb u.a. CDU, Rainer Hinderer u.a. SPD und Dr. Friedrich Bullinger FDP/DVP 07.05.2013 und Antw MVI Drs 15/3466'
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2013-05-07'),
      originators: { people: ['Arnulf Freiherr von Eyb', 'Rainer Hinderer', 'Dr. Friedrich Bullinger'], parties: ['CDU', 'SPD', 'FDP/DVP'] },
      answerers: { ministries: ['MVI'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from long detail link with newline' do
    text = "\r\n  KlAnfr Dr. Friedrich Bullinger FDP/DVP, Helmut Walter Rüeck CDU und\n  Nikolaos Sakkelariou SPD 24.07.2014 und Antw MLR Drs 15/5544"
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2014-07-24'),
      originators: { people: ['Dr. Friedrich Bullinger', 'Helmut Walter Rüeck', 'Nikolaos Sakkelariou'], parties: ['FDP/DVP', 'CDU', 'SPD'] },
      answerers: { ministries: ['MLR'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from detail with multiple ministries' do
    text = 'KlAnfr Rainer Hinderer SPD 01.01.2015 und Antw MVI, ABC und DEF Drs 01/1234'
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2015-01-01'),
      originators: { people: ['Rainer Hinderer'], parties: ['SPD'] },
      answerers: { ministries: ['MVI', 'ABC', 'DEF'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from detail with missing ministry' do
    text = 'KlAnfr Rainer Hinderer SPD 01.01.2015 und Antw Drs 01/1234'
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2015-01-01'),
      originators: { people: ['Rainer Hinderer'], parties: ['SPD'] },
      answerers: { ministries: [] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from detail with wrong published_at position' do
    text = 'KlAnfr Dr. Friedrich Bullinger FDP/DVP und Antw IM 20.06.2014 Drs 15/5345'
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      published_at: Date.parse('2014-06-20'),
      originators: { people: ['Dr. Friedrich Bullinger'], parties: ['FDP/DVP'] },
      answerers: { ministries: ['IM'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from detail with multiple originator parties' do
    text = 'GrAnfr CDU, GRÜNE, SPD und FDP/DVP 13.02.2013 und Antw LReg Drs 15/3038 (40 S.)'
    actual = @scraper.extract_meta(text)
    expected = {
      doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
      published_at: Date.parse('2013-02-13'),
      originators: { people: [], parties: ['CDU','GRÜNE','SPD','FDP/DVP'] },
      answerers: { ministries: ['LReg'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract meta information from major detail link' do
    detail_page = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/baden_wuerttemberg_detail_page_major.html')))
    link = @scraper.get_detail_link(detail_page)
    actual = @scraper.extract_meta(link.text)
    expected = {
      doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
      published_at: Date.parse('2012-04-25'),
      originators: { people: [], parties: ['FDP/DVP'] },
      answerers: { ministries: ['LReg'] }
    }
    assert_equal(expected, actual)
  end

  test 'extract title from Detail' do
    actual = @scraper.extract_detail_title(@detail_page)
    expected = 'Barrierefreier Ausbau der Bahnhöfe auf der Hauptstrecke Stuttgart-Ulm im LKreis Göppingen zwischen Reichenbach/Fils und Eislingen/Fils'
    assert_equal(expected, actual)
  end

  # test 'extract complete paper from page' do
  #   div = @scraper.extract_result_blocks(@result_page)[0]
  #   actual = @scraper.extract_paper(div).first
  #   expected = {
  #     full_reference: '15/6432',
  #     legislative_term: '15',
  #     reference: '6432',
  #     doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
  #     title: 'Barrierefreier Ausbau der Bahnhöfe auf der Hauptstrecke Stuttgart-Ulm im Landkreis Göppingen zwischen Reichenbach/Fils und Eislingen/Fils',
  #     url: 'http://www.landtag-bw.de/scr/initiativen/ini_check.asp?wp=15&drs=6432',
  #     originators: { people: ['Peter Hofelich'], parties: ['SPD'] },
  #     answerers: { ministries: 'MVI' }
  #   }
  #   assert_equal(expected, actual)
  # end
end