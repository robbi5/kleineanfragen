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
    types = ['KA']
    legislative_period = [
      [2013, 11],
      [2013, 12],
      [2014, 1],
      [2014, 2]
    ]
    actual = @scraper::Overview.get_search_urls(@search_url, legislative_period, types)
    expected = [
      @search_url + 'searchInitiativeType=KA&searchYear=2013&searchMonth=11',
      @search_url + 'searchInitiativeType=KA&searchYear=2013&searchMonth=12',
      @search_url + 'searchInitiativeType=KA&searchYear=2014&searchMonth=01',
      @search_url + 'searchInitiativeType=KA&searchYear=2014&searchMonth=02'
    ]
    assert_equal(expected, actual)
  end

  test 'extract result div from resultslist' do
    actual = @scraper.extract_result_blocks(@result_page).size
    expected = 40
    assert_equal(expected, actual)
  end

  test 'extract full reference from result div' do
    div = @scraper.extract_result_blocks(@result_page)[0]
    actual = @scraper.extract_full_reference(div)
    expected = '15/6432'
    assert_equal(expected, actual)
  end

  test 'extract title from result div' do
    div = @scraper.extract_result_blocks(@result_page)[0]
    actual = @scraper.extract_title(div)
    expected = 'Barrierefreier Ausbau der Bahnhöfe auf der Hauptstrecke Stuttgart-Ulm im Landkreis Göppingen zwischen Reichenbach/Fils und Eislingen/Fils'
    assert_equal(expected, actual)
  end

  test 'extract reference from full reference' do
    full_reference = '15/6432'
    actual = @scraper.extract_reference(full_reference)
    expected = ['15', '6432']
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
    actual = @scraper.extract_meta(link)
    expected = {
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      url: 'http://www.landtag-bw.de/scr/initiativen/ini_check.asp?wp=15&drs=6432',
      answerers: 'MVI'
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
  #     originators: 'Peter Hofelich SPD',
  #     answerers: {
  #       ministries: 'MVI'
  #     }
  #   }
  #   assert_equal(expected, actual)
  # end
end