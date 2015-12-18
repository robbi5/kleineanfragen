require 'test_helper'

class NiedersachsenLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = NiedersachsenLandtagScraper
  end

  test 'extract detail info' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/ni/detail.html')))
    block = @scraper.extract_detail_block(@html)
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/1892',
        reference: '1892',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Internetznutzung bei der Polizei - Datenschutz gewährleistet?',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1892.pdf',
        published_at: Date.parse('Tue, 19 Aug 2014'),
        originators: {
          people: ['Jan-Christoph Oetjen'],
          parties: ['FDP']
        },
        is_answer: true,
        answerers: {
          ministries: ['Niedersächsisches Ministerium für Inneres und Sport']
        }
      }, paper)
  end

  test 'extract detail info with attachments' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/ni/detail_attachment.html')))
    block = @scraper.extract_detail_block(@html)
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/2819',
        reference: '2819',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Aktuelle Belegungssituation im niedersächsischen Justizvollzug',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F5000/2501-3000/17-2819.pdf',
        published_at: Date.parse('20.01.2015'),
        originators: {
          people: ['Marco Brunotte', 'Kathrin Wahlmann', 'Andrea Schröder-Ehlers'],
          parties: ['SPD']
        },
        is_answer: true,
        answerers: {
          ministries: ['Niedersächsisches Justizministerium']
        }
      }, paper)
  end

  test 'extract detail info from paper with additional empty row like 4243' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/ni/detail_4243.html')))
    block = @scraper.extract_detail_block(@html)
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/4243',
        reference: '4243',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Haben Wildgänse die Belastung mit Fäkalkeimen an den Nordseebadestränden verursacht?',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F5000/4001-4500/17-4243.pdf',
        published_at: Date.parse('08 Sep 2015'),
        originators: {
          people: ['Axel Miesner'],
          parties: ['CDU']
        },
        is_answer: true,
        answerers: {
          ministries: ['Niedersächsisches Ministerium für Soziales, Gesundheit und Gleichstellung']
        }
      }, paper)
  end

  test 'extract detail info from major interpellation like 4370' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/ni/detail_4370.html')))
    block = @scraper.extract_detail_block(@html)
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/4370',
        reference: '4370',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Was tut die Landesregierung zur Förderung der landwirtschaftlichen Sorgentelefone und der landwirtschaftlichen Familienberatungen in Niedersachsen?',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F5000/4001-4500/17-4370.pdf',
        published_at: Date.parse('2015-09-30'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        is_answer: true,
        answerers: {
          ministries: ['Niedersächsisches Ministerium für Ernährung, Landwirtschaft und Verbraucherschutz']
        }
      }, paper)
  end
end