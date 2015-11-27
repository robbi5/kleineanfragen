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

  test 'extract details 6/4640 without minisitry' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail_6_4640.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

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
        ministries: ['Landesregierung']
    }
    }, paper)
  end

  test 'extract details 6/4151 minor without party' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail_6_4151.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/4151',
        reference: '4151',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Agieren der Staatsanwaltschaft im Zusammenhang mit der öffentlichen Berichterstattung in Sachen „Rabauken-Jäger“',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/36288/agieren-der-staatsanwaltschaft-im-zusammenhang-mit-der-%C3%B6ffentlichen-berichterstattung-in-sachen-%E2%80%9Erabauken-j%C3%A4ger%E2%80%9C.pdf',
        published_at: Date.parse('Wed, 22 Jul 2015'),
        originators: {
          people: ['Barbara Borchardt'],
          parties: []
        },
        answerers: {
          ministries: ['Justizministerium']
        }
      }, paper)
  end

  test 'extract details major interpellation with Answerers' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail_6_3870.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/3870',
        reference: '3870',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: '20 Jahre Verfassung des Landes Mecklenburg-Vorpommern',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/35928/20-jahre-verfassung-des-landes-mecklenburg-vorpommern.pdf',
        published_at: Date.parse('Tue, 31 Mar 2015'),
        originators: {
          people: [],
          parties: ['DIE LINKE']
        },
        answerers: {
          ministries: ['Staatskanzlei']
        }
      }, paper)
  end

  test 'extract details major interpellation without Answerers' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/meck_pomm_landtag_scraper_detail_6_2572.html')))
    body = html.search("//table[@id = 'parldokresult']")
    paper = @scraper.extract(body.at_css('.title'))

    assert_equal(
      {
        legislative_term: '6',
        full_reference: '6/2572',
        reference: '2572',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Linksextremismus in Mecklenburg-Vorpommern',
        url: 'http://www.dokumentation.landtag-mv.de/Parldok/dokument/34182/linksextremismus-in-mecklenburg-vorpommern.pdf',
        published_at: Date.parse('Fri, 13 Dec 2013'),
        originators: {
          people: [],
          parties: ['NPD']
        },
        answerers: {
          ministries: []
        }
      }, paper)
  end
end