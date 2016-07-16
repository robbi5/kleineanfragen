require 'test_helper'

class RheinlandPfalzLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/rp/overview_17.html')))
    @scraper = RheinlandPfalzLandtagScraper
  end

  test 'extract blocks from search result page' do
    blocks = @scraper.extract_records(@html)
    assert_equal 10, blocks.size
  end

  test 'extract title from result block' do
    blocks = @scraper.extract_records(@html).first
    title = @scraper.extract_title(blocks)
    assert_equal 'Auswirkungen eines Komplettumzuges der Bundesregierung nach Berlin auf Rheinland-Pfalz', title
  end

  test 'extract details from result block' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    html = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
       <br>Kleine Anfrage  Guido Ernst (CDU), Horst Gies (CDU) 15.06.2016 Drucksache  <a href="http://www.landtag.rlp.de/landtag/drucksachen/136-17.pdf" target="new"> 17/136</a>  (1 S.)<br>Antwort zu Drs 17/136  Guido Ernst (CDU), Horst Gies (CDU), Staatskanzlei 07.07.2016 Drucksache  <a href="http://www.landtag.rlp.de/landtag/drucksachen/372-17.pdf" target="new"> 17/372</a>
    END
    assert_equal html, details.inner_html
  end

  test 'extract link from details' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta_rows = @scraper.extract_meta_rows(details)
    link = @scraper.extract_link(meta_rows)
    assert_equal '<a href="http://www.landtag.rlp.de/landtag/drucksachen/372-17.pdf" target="new"> 17/372</a>', link.to_html
  end

  test 'extract full reference from link' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta_rows = @scraper.extract_meta_rows(details)
    link = @scraper.extract_link(meta_rows)
    full_reference = @scraper.extract_full_reference(link)
    assert_equal '17/372', full_reference
  end

  test 'extract reference and legislative_term from full reference' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta_rows = @scraper.extract_meta_rows(details)
    link = @scraper.extract_link(meta_rows)
    full_reference = @scraper.extract_full_reference(link)
    legislative_term, reference = @scraper.extract_reference(full_reference)

    assert_equal '17', legislative_term
    assert_equal '372', reference
  end

  test 'extract url from link' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta_rows = @scraper.extract_meta_rows(details)
    link = @scraper.extract_link(meta_rows)
    url = @scraper.extract_url(link)
    assert_equal 'http://www.landtag.rlp.de/landtag/drucksachen/372-17.pdf', url
  end

  test 'extract meta from details' do
    block = @scraper.extract_records(@html).first
    details = @scraper.extract_detail_block(block)
    meta = @scraper.extract_meta(details)
    assert_equal 'Guido Ernst (CDU), Horst Gies (CDU)', meta[:originators]
    assert_equal 'Staatskanzlei', meta[:answerers]
    assert_equal '07.07.2016', meta[:published_at]
  end

  test 'extract complete paper' do
    block = @scraper.extract_records(@html).first
    paper = @scraper.extract_paper(block, check_pdf: false)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/372',
        reference: '372',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Auswirkungen eines Komplettumzuges der Bundesregierung nach Berlin auf Rheinland-Pfalz',
        url: 'http://www.landtag.rlp.de/landtag/drucksachen/372-17.pdf',
        published_at: Date.parse('Thu, 07 Jul 2016'),
        originators: {
          people: ['Guido Ernst', 'Horst Gies'],
          parties: ['CDU']
        },
        is_answer: true,
        answerers: {
          ministries: ['Staatskanzlei']
        },
        source_url: 'http://opal.rlp.de/starweb/OPAL_extern/servlet.starweb?path=OPAL_extern/PDOKUFL.web' +
          '&id=ltrpopalfastlink&format=PDOKU_Vollanzeige_Report&search=WP%3D17+AND+DART%3DD+AND+DNR%2CKORD%3D372'
      }, paper)
  end
end