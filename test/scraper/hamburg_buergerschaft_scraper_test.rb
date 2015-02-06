require 'test_helper'

class HamburgBuergerschaftScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = HamburgBuergerschaftScraper
  end

  test 'extract dates' do
    assert_equal(
      [
        [Date.parse('01.01.2015'), Date.parse('03.01.2015')],
        [Date.parse('04.01.2015'), Date.parse('06.01.2015')],
        [Date.parse('07.01.2015'), Date.parse('09.01.2015')],
        [Date.parse('10.01.2015'), Date.parse('12.01.2015')]
      ],
      @scraper.extract_date_ranges('(1.1.2015 - 12.1.2015)'))
  end

  test 'extract paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hamburg_search_result.html')))
    assert_equal(
      {
        legislative_term: '19',
        full_reference: '19/1745',
        reference: '1745',
        title: 'Stadtwerke (1): Finanzierung von „Hamburg Energie“ im Haushaltsplan-Entwurf 2009/2010',
        url: 'http://www.buergerschaft-hh.de/Parldok/tcl/PDDocView.tcl?mode=show&dokid=24592&page=0',
        published_at: Date.parse('8.12.2008'),
        originators: {
                people: ['Dora Heyenn', 'Dr. Joachim Bischoff', 'Wolfgang Joithe-von Krosigk'],
                parties: ['Fraktion DIE LINKE']
            },
        },
      @scraper.extract(@html.css('td.pd_titel').first))
  end
end