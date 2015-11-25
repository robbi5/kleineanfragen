require 'test_helper'

class MeckPommLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = MeckPommLandtagScraper
  end

  test 'extract details' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/1596',
        reference: '1596',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Ausschreibung der Betreibung von Gemeinschaftsunterkünften',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/32932/ausschreibung-der-betreibung-von-gemeinschaftsunterk%C3%BCnften.pdf',
        published_at: Date.parse('Fri, 13 Mar 2013'),
        originators: {
          people: ['Silke Gajek'],
          parties: ['B90/GR']
        },
        answerers: {
          ministries: ['Landesregierung']
        }
      }, paper)
  end

  test 'extract details 6/1597' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail_6_1597.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/1597',
        reference: '1597',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Berufs- und Schülerverkehr Fahrrad',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/32931/berufs-und-sch%C3%BClerverkehr-fahrrad.pdf',
        published_at: Date.parse('Mon, 18 Mar 2013'),
        originators: {
          people: ['Johann-Georg Jaeger'],
          parties: ['B90/GR']
        },
        answerers: {
          ministries: ['Ministerium für Energie, Infrastruktur und Landesentwicklung']
        }
      }, paper)
  end
end