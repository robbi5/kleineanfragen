require 'test_helper'

class BadenWuerttembergLandtagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BadenWuerttembergLandtagScraper
    @page = Mechanize.new.get('file://' + Rails.root.join('test/fixtures/baden_wuerttemberg_legislative_term_page.html').to_s)
  end

  test 'get legislative start and end date from url' do
    legislative = BadenWuerttembergLandtagScraper::Overview.new(15)
    actual = legislative.extract_legislative_dates(@page)
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
    actual = BadenWuerttembergLandtagScraper::Overview.get_legislative_period(date1, date2)
    assert_equal(expected, actual)
  end
end