require 'test_helper'

class HamburgBuergerschaftScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = HamburgBuergerschaftScraper
  end

  test 'extract dates' do
    assert_equal(
      [
        [Date.parse('2015-01-01'), Date.parse('2015-01-03')],
        [Date.parse('2015-01-04'), Date.parse('2015-01-06')],
        [Date.parse('2015-01-07'), Date.parse('2015-01-09')],
        [Date.parse('2015-01-10'), Date.parse('2015-01-12')]
      ],
      @scraper.extract_date_ranges('(01.01.15 - 12.01.15)'))
  end

  test 'extract paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hamburg_search_result.html')))
    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/1745',
        reference: '1745',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Stadtwerke (1): Finanzierung von „Hamburg Energie“ im Haushaltsplan-Entwurf 2009/2010',
        url: 'http://www.buergerschaft-hh.de/Parldok/tcl/PDDocView.tcl?mode=show&dokid=24592&page=0',
        published_at: Date.parse('8.12.2008'),
        originators: {
          people: ['Dora Heyenn', 'Dr. Joachim Bischoff', 'Wolfgang Joithe-von Krosigk'],
          parties: ['DIE LINKE']
        }
      },
      @scraper.extract(@html.css('td.pd_titel').first))
  end
end