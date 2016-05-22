require 'test_helper'

class RheinlandPfalzLandtagScraperDetailTest < ActiveSupport::TestCase
  def setup
    @scraper = RheinlandPfalzLandtagScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail.html')))
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
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D4608'
      }, paper)
  end

  test 'extract paper with additional link like in 16/4097' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail_4097.html')))
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
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D4097'
      }, paper)
  end

  test 'extract paper with multiple ministries like in 16/3813' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail_3813.html')))
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
        ] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D3813'
      }, paper)
  end

  test 'extract paper without party like 16/863' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail_863.html')))
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
        ] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D863'
      }, paper)
  end

  test 'extract paper with two meta_rows like 16/1734' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail_1734.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/1734',
        reference: '1734',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Aktive Stadt- und Ortsteilzentren. Das Zentrenprogramm der Städtebauförderung',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/1734-16.pdf',
        published_at: Date.parse('24.10.2012'),
        originators: { people: ['Michael Billen'], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: [
          'Ministerium des Innern, für Sport und Infrastruktur'
        ] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D1734'
      }, paper)
  end

  test 'extract paper with ministry staatskanzlei like 16/4965' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/detail_4965.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4965',
        reference: '4965',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Umgang der Ministerpräsidentin mit Kritik zu den Abläufen rund um den Nürburgring',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4965-16.pdf',
        published_at: Date.parse('2015-04-30'),
        originators: { people: ['Alexander Licht'], parties: ['CDU'] },
        is_answer: true,
        answerers: { ministries: [
          'Staatskanzlei'
        ] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D4965'
      }, paper)
  end

  test 'extract complete paper from Major' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/major_detail.html')))
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
        answerers: { ministries: ['Ministerium für Integration, Familie, Kinder, Jugend und Frauen'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D4788'
      }, paper)
  end

  test 'extract complete paper from Major with more information and links' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/major_detail_4503.html')))
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
        answerers: { ministries: ['Ministerium für Soziales, Arbeit, Gesundheit und Demografie'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D4503'
      }, paper)
  end

  test 'extract complete paper from Major with an additional answer' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/major_detail_579.html')))
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
        answerers: { ministries: ['Ministerium des Innern, für Sport und Infrastruktur'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D579'
      }, paper)
  end

  test 'extract complete major paper with multiple originator parties' do
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/major_detail_2887.html')))
    record = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(record, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/2887',
        reference: '2887',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Bilanz und Perspektiven für die Weiterentwicklung des Bologna-Prozesses in Rheinland-Pfalz',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/2887-16.pdf',
        published_at: Date.parse('15.10.2013'),
        originators: { people: [], parties: ['SPD', 'BÜNDNIS 90/DIE GRÜNEN'] },
        is_answer: true,
        answerers: { ministries: ['Ministerium für Bildung, Wissenschaft, Weiterbildung und Kultur'] },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web&id=ltrpopalfastlink' +
          '&format=PDOKU_Vollanzeige_Report&search=WP%3D16+AND+DART%3DD+AND+DNR%2CKORD%3D2887'
      }, paper)
  end
end
