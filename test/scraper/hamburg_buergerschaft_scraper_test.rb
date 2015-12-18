require 'test_helper'

class HamburgBuergerschaftScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = HamburgBuergerschaftScraper
  end

  test 'extract minor paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hh/result.html')))
    paper = @scraper.extract(@html.css('.title').first)
    assert_equal(
      {
        legislative_term: '21',
        full_reference: '21/159',
        reference: '159',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Wann werden endlich die Bahnhofsknotenpunkte Hamburg und Harburg entlastet und Pendler sowie die Harburgerinnen und Harburger nicht mehr länger wie Ölsardinen in Züge gepresst?',
        url: 'https://www.buergerschaft-hh.de/ParlDok/dokument/48286/wann-werden-endlich-die-bahnhofsknotenpunkte-hamburg-und-harburg-entlastet-und-pendler-sowie-die-harburgerinnen-und-harburger-nicht-mehr-l%C3%A4nger.pdf',
        published_at: Date.parse('2015-03-31'),
        originators: {
          people: ['Birgit Stöver'],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Senat']
        }
      }, paper)
  end

  test 'extract major paper' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hh/result_1549.html')))
    paper = @scraper.extract(@html.css('.title').first)
    assert_equal(
      {
        legislative_term: '21',
        full_reference: '21/1549',
        reference: '1549',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Hamburg – Stadt mit Courage: Landesprogramm zur Förderung demokratischer Kultur, Vorbeugung und Bekämpfung von Rechtsextremismus und das Beratungsnetzwerk gegen Rechtsextremismus (BNW)',
        url: 'https://www.buergerschaft-hh.de/ParlDok/dokument/49756/hamburg-%E2%80%93-stadt-mit-courage-landesprogramm-zur-f%C3%B6rderung-demokratischer-kultur-vorbeugung-und-bek%C3%A4mpfung-von-rechtsextremismus-und-das-beratungsnetzwerk.pdf',
        published_at: Date.parse('2015-09-10'),
        originators: {
          people: [
            'Dr. Ludwig Flocken',
            'Dirk Nockemann',
            'Dr. Alexander Wolf',
            'Andrea Oelschlaeger',
            'Dr. Joachim Körner'
          ],
          parties: ['AfD']
        },
        answerers: {
          ministries: ['Senat']
        }
      }, paper)
  end

  test 'extract other major paper, same party' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/hh/result_2013.html')))
    paper = @scraper.extract(@html.css('.title').first)
    assert_equal(
      {
        legislative_term: '21',
        full_reference: '21/2013',
        reference: '2013',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Auswärtige Unterbringung bei den Hilfen zur Erziehung',
        url: 'https://www.buergerschaft-hh.de/ParlDok/dokument/50260/ausw%C3%A4rtige-unterbringung-bei-den-hilfen-zur-erziehung.pdf',
        published_at: Date.parse('2015-10-23'),
        originators: {
          people: [
            'Sabine Boeddinghaus',
            'Deniz Celik',
            'Martin Dolzer',
            'Norbert Hackbusch',
            'Inge Hannemann',
            'Stephan Jersch',
            'Cansu Özdemir',
            'Christiane Schneider',
            'Heike Sudmann',
            'Mehmet Yildiz'
          ],
          parties: ['DIE LINKE']
        },
        answerers: {
          ministries: ['Senat']
        }
      }, paper)
  end
end