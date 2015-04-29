require 'test_helper'

class RheinlandPfalzLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = RheinlandPfalzLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail.html')))
  end

  test 'extract complete paper' do
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4608',
        reference: '4608',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Grundversorgung mit leistungsfähigem Breitband im Wahlkreis 29',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4608-16.pdf',
        published_at: Date.parse('13.02.2015'),
        originators: { people: ['Dorothea Schäfer'], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] }
      }, paper)
  end

  test 'extract paper with additional link like in 16/4097' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail_4097.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4097',
        reference: '4097',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Laufende Beihilfeverfahren/Antwort der Landesregierung',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4097-16.pdf',
        published_at: Date.parse('14.10.2014'),
        originators: { people: ['Alexander Licht'], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] }
      }, paper)
  end

  test 'extract paper with multiple ministries like in 16/3813' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail_3813.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/3813',
        reference: '3813',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Erstes rheinland-pfälzisches Green Hospital entsteht in Meisenheim',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/3813-16.pdf',
        published_at: Date.parse('25.07.2014'),
        originators: { people: ['Ulrich Steinbach', 'Andreas Hartenfels'], parties: ['BÜNDNIS 90/DIE GRÜNEN'] },
        is_answer: true,
        answerers: { ministries: [
          'Ministerium für Wirtschaft, Klimaschutz, Energie und Landesplanung',
          'Ministerium für Soziales, Arbeit, Gesundheit und Demografie'
        ] }
      }, paper)
  end

  test 'extract paper without party like 16/863' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_detail_863.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/863',
        reference: '863',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Mehrfache Verschiebung der Mediation zur Geothermie',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/863-16.pdf',
        published_at: Date.parse('07.02.2012'),
        originators: { people: ['Martin Brandl'], parties: [] },
        is_answer: true,
        answerers: { ministries: [
          'Ministerium für Wirtschaft, Klimaschutz, Energie und Landesplanung'
        ] }
      }, paper)
  end

  test 'extract complete paper from Major' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_major_detail.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4788',
        reference: '4788',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Situation kinderreicher Familien in Rheinland-Pfalz',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4788-16.pdf',
        published_at: Date.parse('20.03.2015'),
        originators: { people: [], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium für Integration, Familie, Kinder, Jugend und Frauen'] }
      }, paper)
  end

  test 'extract complete paper from Major with more information and links' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_major_detail_4503.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4503',
        reference: '4503',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Sterben in Würde',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4503-16.pdf',
        published_at: Date.parse('21.01.2015'),
        originators: { people: [], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium für Soziales, Arbeit, Gesundheit und Demografie'] }
      }, paper)
  end

  test 'extract complete paper from Major with an additional answer' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rheinland_pfalz_landtag_scraper_major_detail_579.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/579',
        reference: '579',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Prüfung vergaberechtlicher sowie weiterer rechtlicher Fragestellungen im Rahmen der Verträge zur Umsetzung des Zukunftskonzeptes Nürburgring',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/579-16.pdf',
        published_at: Date.parse('16.11.2011'),
        originators: { people: [], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] }
      }, paper)
  end
end
