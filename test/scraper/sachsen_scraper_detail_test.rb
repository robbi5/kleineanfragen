require 'test_helper'

class SachsenScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = SachsenScraper
  end

  test 'extract detail first page' do
    content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sn/detail_search.html')))

    item = @scraper.extract_overview_items(content).first
    paper = @scraper.extract_detail_paper(item)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/1711',
        reference: '1711',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Jahrgangsübergreifender Unterricht an sächsischen Grundschulen',
        url: nil,
        published_at: Date.parse('2015-05-17'),
        originators: {
          people: ['Petra Zais'],
          parties: ['GRÜNE']
        },
        is_answer: nil
      }, paper)
  end

  test 'extract detail vorgang page' do
    content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sn/detail_vorgang.html')))

    answered_at = @scraper::Detail.extract_answered_at(content)
    buttons = @scraper::Detail.extract_pdf_buttons(content)

    assert_equal '10.06.2015', answered_at.text
    assert_equal(
      [
        'ctl00$masterContentCallback$content$tabTreffer$trefferDataView$IT0$anzeige$1711_0_Drs_6_no$btn',
        'ctl00$masterContentCallback$content$tabTreffer$trefferDataView$IT0$anzeige$1711_1_Drs_6_no$btn'
      ], buttons)
  end

  test 'generate viewer url' do
    button_name = 'ctl00$masterContentCallback$content$tabTreffer$trefferDataView$IT0$anzeige$1711_1_Drs_6_no$btn'
    url = @scraper::Detail.extract_viewer_url(button_name)
    assert_equal 'http://edas.landtag.sachsen.de/viewer.aspx?dok_nr=1711&dok_art=Drs&leg_per=6&pos_dok=1', url
  end

  test 'extract answerer from vorgang page' do
    content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sn/detail_vorgang_vorgang.html')))

    answerer = @scraper::Detail.extract_vorgang_answerer(content)

    assert_equal 'SMS', answerer
  end
end