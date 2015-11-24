require 'test_helper'

class MeckPommOverviewScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = MeckPommLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_overview.html')))
    @body = @html.search("//table[@id = 'parldokresult']")
  end

  # webpage states that it shows 671 results but actually displays 482
  test 'extract normal overview items' do
    title_el = @body.css('.title').first
    paper = @scraper.extract(title_el)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/4677',
        reference: '4677',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Ukrainistik und Baltistik an der Universität Greifswald',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/36897/ukrainistik-und-baltistik-an-der-universit%C3%A4t-greifswald.pdf',
        published_at: Date.parse('Thu, 19 Nov 2015'),
        originators: {
          people: ['Johannes Saalfeld'],
          parties: ['B90/GR']
        },
        answerers: {
          ministries: ['Ministerium für Bildung, Wissenschaft und Kultur']
        }
      }, paper)
  end

  test 'extract overview items with special layout' do
    title_el = @body.css('.title')[5]
    paper = @scraper.extract(title_el)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/4640',
        reference: '4640',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Verfahren zur Verwendung zusätzlicher Mittel in der Kulturförderung',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/36869/verfahren-zur-verwendung-zus%C3%A4tzlicher-mittel-in-der-kulturf%C3%B6rderung.pdf',
        published_at: Date.parse('Tue, 17 Nov 2015'),
        originators: {
          people: ['Torsten Koplin'],
          parties: ['DIE LINKE']
        },
        answerers: {
          ministries: []
        }
      }, paper)
  end

  test 'extract overview items with two originators' do
    title_el = @body.css('.title').last
    paper = @scraper.extract(title_el)

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/4635',
        reference: '4635',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Beförderung von Kindern zu Kindertagesstätten',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/36865/bef%C3%B6rderung-von-kindern-zu-kindertagesst%C3%A4tten.pdf',
        published_at: Date.parse('Wed, 11 Nov 2015'),
        originators: {
          people: ['Jürgen Suhr', 'Silke Gajek'],
          parties: ['B90/GR']
        },
        answerers: {
          ministries: ['Ministerium für Arbeit, Gleichstellung und Soziales']
        }
      }, paper)
  end
end