require 'test_helper'

class RheinlandPfalzLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/overview.html')))
    @scraper = RheinlandPfalzLandtagScraper
  end

  test 'extract blocks from search result page' do
    blocks = @scraper.extract_records(@html)
    assert_equal 10, blocks.size
  end

  test 'extract title from result block' do
    blocks = @scraper.extract_records(@html).first
    title = @scraper.extract_title(blocks)
    assert_equal 'Bedingte Zustimmungen zum Nationalpark VIII', title
  end

  test 'extract details from result block' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    html = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
       <br> Kleine Anfrage 2809  Horst Gies (CDU) und Antwort Ministerium für Umwelt, Landwirtschaft, Ernährung, Weinbau und Forsten 08.12.2014 Drucksache  <a href="http://www.landtag.rlp.de/landtag/drucksachen/4324-16.pdf" target="new"> 16/4324</a>  (2 S.)
    END
    assert_equal html, details.inner_html
  end

  test 'extract link from details' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    link = @scraper.extract_link(details)
    assert_equal '<a href="http://www.landtag.rlp.de/landtag/drucksachen/4324-16.pdf" target="new"> 16/4324</a>', link.to_html
  end

  test 'extract full reference from link' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    link = @scraper.extract_link(details)
    full_reference = @scraper.extract_full_reference(link)
    assert_equal '16/4324', full_reference
  end

  test 'extract reference and legislative_term from full reference' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    link = @scraper.extract_link(details)
    full_reference = @scraper.extract_full_reference(link)
    legislative_term, reference = @scraper.extract_reference(full_reference)

    assert_equal '16', legislative_term
    assert_equal '4324', reference
  end

  test 'extract url from link' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    link = @scraper.extract_link(details)
    url = @scraper.extract_url(link)
    assert_equal 'http://www.landtag.rlp.de/landtag/drucksachen/4324-16.pdf', url
  end

  test 'extract meta from details' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta = @scraper.extract_meta(details)
    assert_equal 'Horst Gies (CDU)', meta[:originators]
    assert_equal 'Ministerium für Umwelt, Landwirtschaft, Ernährung, Weinbau und Forsten', meta[:answerers]
    assert_equal '08.12.2014', meta[:published_at]
  end

  test 'extract complete paper' do
    block = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(block, check_pdf: false)

    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4324',
        reference: '4324',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Bedingte Zustimmungen zum Nationalpark VIII',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4324-16.pdf',
        published_at: Date.parse('Mon, 08 Dec 2014'),
        originators: {
          people: ['Horst Gies'],
          parties: ['CDU']
        },
        is_answer: true,
        answerers: {
          ministries: ['Ministerium für Umwelt, Landwirtschaft, Ernährung, Weinbau und Forsten']
        },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSHFLMORE.web' +
          '&id=LTRPOPALDOKFL&format=LISSH_MoreDokument_Report&search=%28DART%3DD+AND+WP%3D16+AND+DNR%2CKORD%3D4324%29'
      }, paper)
  end

  test 'extract meta from details in major paper' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/overview_major.html')))
    block = @scraper.extract_records(html).first
    details = @scraper.extract_detail_block(block)
    meta = @scraper.extract_meta(details)
    assert_equal ['CDU'], meta[:originators]
    assert_equal 'Ministerium für Integration, Familie, Kinder, Jugend und Frauen', meta[:answerers]
    assert_equal '20.03.2015', meta[:published_at]
  end

  test 'extract complete major paper' do
    html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/overview_major.html')))
    block = @scraper.extract_records(html).first
    paper = @scraper.extract_paper(block, check_pdf: false)
    assert_equal(
      {
        legislative_term: '16',
        full_reference: '16/4788',
        reference: '4788',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: 'Situation kinderreicher Familien in Rheinland-Pfalz',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/4788-16.pdf',
        published_at: Date.parse('2015-03-20'),
        originators: {
          people: [],
          parties: ['CDU']
        },
        is_answer: true,
        answerers: {
          ministries: ['Ministerium für Integration, Familie, Kinder, Jugend und Frauen']
        },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/LISSHFLMORE.web' +
          '&id=LTRPOPALDOKFL&format=LISSH_MoreDokument_Report&search=%28DART%3DD+AND+WP%3D16+AND+DNR%2CKORD%3D4788%29'
      }, paper)
  end
end