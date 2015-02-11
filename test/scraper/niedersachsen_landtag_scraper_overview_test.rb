require 'test_helper'

class NiedersachsenLandtagScraperOverviewTest < ActiveSupport::TestCase
  def setup
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/niedersachsen_landtag_scraper_overview.html')))
    @scraper = NiedersachsenLandtagScraper
  end

  test 'extract blocks from search result page' do
    blocks = @scraper.extract_blocks(@html)
    assert_equal 655, blocks.size
  end

  test 'extract title from result block' do
    block = @scraper.extract_blocks(@html).first
    title = @scraper.extract_title(block)
    assert_equal '640 000 Euro für Elektromobilität?', title
  end

  test 'extract container from result block' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    html = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
       <br>Kleine Anfrage zur schriftlichen Beantwortung Martin Bäumer (CDU)   04.07.2014 Drucksache 
      <a href="http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1928.pdf" target="new">17/1928</a>  (S.1)<br>Antwort Niedersächsisches Ministerium für Inneres und Sport   06.08.2014 Drucksache 
      <a href="http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1928.pdf" target="new">17/1928</a>  (S.1-3)
    END
    assert_equal html, container.inner_html
  end

  test 'extract last a-element from container' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    link = @scraper.extract_link(container)
    assert_equal '<a href="http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1928.pdf" target="new">17/1928</a>', link.to_html
  end

  test 'extract full reference from link' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    link = @scraper.extract_link(container)
    full_reference = @scraper.extract_full_reference(link)
    assert_equal '17/1928', full_reference
  end

  test 'extract reference from full reference' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    link = @scraper.extract_link(container)
    full_reference = @scraper.extract_full_reference(link)
    legislative_term, reference = @scraper.extract_reference(full_reference)

    assert_equal '17', legislative_term
    assert_equal '1928', reference
  end

  test 'extract url from link' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    link = @scraper.extract_link(container)
    url = @scraper.extract_url(link)
    assert_equal 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1928.pdf', url
  end

  test 'extract results from container' do
    block = @scraper.extract_blocks(@html).first
    container = @scraper.extract_container(block)
    meta = @scraper.extract_meta(container)
    assert_equal 'Martin Bäumer (CDU)', meta[:originators]
    assert_equal 'Niedersächsisches Ministerium für Inneres und Sport', meta[:answerers]
    assert_equal '06.08.2014', meta[:published_at]
  end

  test 'extract results from container all' do
    @scraper.extract_blocks(@html).each do |block|
      container = @scraper.extract_container(block)
      meta = @scraper.extract_meta(container)
      assert !meta.nil?, container.text
    end
  end

  test 'extract broken paper should throw error' do
    block = Nokogiri::HTML("<div>Nope.</div>")
    assert_raises RuntimeError do
      @scraper.extract_paper(block)
    end
  end

  test 'extract complete paper' do
    block = @scraper.extract_blocks(@html).first
    paper = @scraper.extract_paper(block)

    assert_equal(
      {
        legislative_term: '17',
        full_reference: '17/1928',
        reference: '1928',
        title: '640 000 Euro für Elektromobilität?',
        url: 'http://www.landtag-niedersachsen.de/Drucksachen/Drucksachen%5F17%5F2500/1501-2000/17-1928.pdf',
        published_at: Date.parse('Wed, 06 Aug 2014'),
        originators: {
          people: ['Martin Bäumer'],
          parties: ['CDU']
        },
        answerers: {
          ministries: ['Niedersächsisches Ministerium für Inneres und Sport']
        }
      }, paper)
  end
end