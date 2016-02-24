require 'test_helper'

class BrandenburgScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BrandenburgLandtagScraper
    @overview = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bb/overview.html')).force_encoding('windows-1252'))
    @detail = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bb/detail.html')).force_encoding('windows-1252'))
  end

  # 25 results
  test 'extract overview items' do
    body = @scraper.extract_body(@overview)
    items = @scraper.extract_overview_items(body)
    assert_equal 25, items.length
  end

  test 'extract title from item row' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    title = @scraper.extract_title(item)
    assert_equal 'Kreisumlagen in Brandenburg', title
  end

  test 'extract originators' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    originator_text = item.at_css('span[name="OFR_BASIS3"]').text.strip
    originators = @scraper.extract_originators(originator_text)

    assert_equal 'Raik Nowka (CDU), Steeven Bretz (CDU)', originators
  end

  test 'extract answer data' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    answer_text_el = item.css('.topic2').last
    ad = @scraper.extract_answer_data(answer_text_el.text)

    assert_equal Date.parse('2015-12-21'), ad[:published_at]
    assert_equal '6/3233', ad[:full_reference]
  end

  test 'extract overview paper' do
    body = @scraper.extract_body(@overview)
    items = @scraper.extract_overview_items(body)
    item = items.first
    paper = @scraper.extract_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/3264',
        reference: '3264',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Windenergieanlagen - Begleitung der Schwertransporte durch die Polizei',
        url: 'https://www.parlamentsdokumentation.brandenburg.de/parladoku/w6/drs/ab_3200/3264.pdf',
        published_at: Date.parse('2015-12-30'),
        is_answer: true,
        originators: { people: ['Thomas Jung', 'Andreas Kalbitz'], parties: ['AfD'] },
        source_url: 'https://www.parlamentsdokumentation.brandenburg.de/starweb/LBB/ELVIS/servlet.starweb?path=LBB/ELVIS/LISSH.web&Standardsuche=yes&search=WP%3D6+AND+DNR%3D3264'
      }, paper)
  end

  test 'extract detail paper' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    paper = @scraper.extract_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/3233',
        reference: '3233',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Kreisumlagen in Brandenburg',
        url: 'https://www.parlamentsdokumentation.brandenburg.de/parladoku/w6/drs/ab_3200/3233.pdf',
        published_at: Date.parse('2015-12-21'),
        originators: {
          people: ['Raik Nowka', 'Steeven Bretz'],
          parties: ['CDU']
        },
        is_answer: true,
        source_url: 'https://www.parlamentsdokumentation.brandenburg.de/starweb/LBB/ELVIS/servlet.starweb?path=LBB/ELVIS/LISSH.web&Standardsuche=yes&search=WP%3D6+AND+DNR%3D3233'
      }, paper)
  end

  test 'extract major interpellation detail paper 2926' do
    detail = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bb/detail_2926.html')).force_encoding('windows-1252'))
    body = @scraper.extract_body(detail)
    item = @scraper.extract_detail_item(body)
    paper = @scraper.extract_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/2926',
        reference: '2926',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Medienwirtschaft im Land Brandenburg',
        url: 'https://www.parlamentsdokumentation.brandenburg.de/parladoku/w6/drs/ab_2900/2926.pdf',
        published_at: Date.parse('2015-11-05'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        is_answer: true,
        source_url: 'https://www.parlamentsdokumentation.brandenburg.de/starweb/LBB/ELVIS/servlet.starweb?path=LBB/ELVIS/LISSH.web&Standardsuche=yes&search=WP%3D6+AND+DNR%3D2926'
      }, paper)
  end

  test 'extract date ranges' do
    opt = Struct.new(:value, :text)
    options = [
      opt.new(6, '6. Wahlperiode (seit 08.10.2014)'),
      opt.new(5, '5. Wahlperiode (21.10.2009 - 08.10.2014)'),
      opt.new(4, '4. Wahlperiode (13.10.2004 - 21.10.2009)'),
      opt.new('1:6', 'alle Wahlperioden'),
    ]
    ranges = @scraper.get_daterange(options)

    assert_equal(
      {
        6 => ['08.10.2014', nil],
        5 => ['21.10.2009', '08.10.2014'],
        4 => ['13.10.2004', '21.10.2009']
      }, ranges)
  end

  test 'get dates from period' do
    period = ['21.10.2009', '08.10.2014']
    dates = @scraper.get_dates period

    assert_equal(
      [
        [Date.parse('2009-10-21'), Date.parse('2010-10-18')],
        [Date.parse('2010-10-19'), Date.parse('2011-10-16')],
        [Date.parse('2011-10-17'), Date.parse('2012-10-13')],
        [Date.parse('2012-10-14'), Date.parse('2013-10-11')],
        [Date.parse('2013-10-12'), Date.parse('2014-10-08')]
      ], dates)
  end

  test 'get dates from current period' do
    period = ['08.10.2014', nil]
    travel_to Date.parse('2016-01-11') do
      dates = @scraper.get_dates period

      assert_equal(
        [
          [Date.parse('2014-10-08'), Date.parse('2015-01-07')],
          [Date.parse('2015-01-08'), Date.parse('2015-04-09')],
          [Date.parse('2015-04-10'), Date.parse('2015-07-10')],
          [Date.parse('2015-07-11'), Date.parse('2015-10-10')],
          [Date.parse('2015-10-11'), Date.parse('2016-01-10')],
          [Date.parse('2016-01-11'), (Date.today + 1.day)]
        ], dates)
    end
  end
end