require 'test_helper'

class BundestagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BundestagScraper
    @content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bt/detail.html')).force_encoding('windows-1252')).to_s
    @content_xml = @scraper.extract_doc(@content)
  end

  test 'extract details' do
    assert_equal(Paper::DOCTYPE_MINOR_INTERPELLATION, @scraper.extract_doctype(@content_xml))
    assert_equal('Beantwortet', @scraper.extract_status(@content_xml))
    assert_equal('Einsatz von Flugzeugen, Hubschraubern und Drohnen beim G7-Gipfel in Bayern', @scraper.extract_title(@content_xml))
  end

  test 'extract complete paper' do
    paper = @scraper.scrape_content(@content, 'http://dipbt.bundestag.de/extrakt/ba/WP18/677/67715.html')
    assert_equal(
      {
        legislative_term: 18,
        full_reference: '18/5714',
        reference: '5714',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Einsatz von Flugzeugen, Hubschraubern und Drohnen beim G7-Gipfel in Bayern',
        url: 'http://dipbt.bundestag.de/dip21/btd/18/057/1805714.pdf',
        published_at: Date.parse('2015-07-31'),
        originators: {
          people: ['Eva Bulling-Schröter', 'Klaus Ernst'],
          parties: ['DIE LINKE']
        },
        is_answer: true,
        answerers: {
          ministries: ['Bundeskanzleramt']
        },
        source_url: 'http://dipbt.bundestag.de/extrakt/ba/WP18/677/67715.html'
      }, paper)
  end

  test 'extract incomplete paper - first half' do
    content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bt/detail_18_13660.html')).force_encoding('windows-1252')).to_s
    content_xml = @scraper.extract_doc(content)
    err = assert_raises(BundestagScraper::NoDetailUrl) do
      paper = @scraper.scrape_content(content, 'http://dipbt.bundestag.de/extrakt/ba/WP18/839/83903.html')
    end

    assert_equal(
      {
        legislative_term: 18,
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Neonazis als mögliche Quellen von Nachrichtendiensten',
        source_url: 'http://dipbt.bundestag.de/extrakt/ba/WP18/839/83903.html'
      }, err.extract)
  end

  test 'extract incomplete paper - other half' do
    content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bt/detail_18_13660_procedure.html')).force_encoding('windows-1252')).to_s
    content_xml = @scraper.extract_doc(content)

    extract = {
      legislative_term: 18,
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: 'Neonazis als mögliche Quellen von Nachrichtendiensten',
      source_url: 'http://dipbt.bundestag.de/extrakt/ba/WP18/839/83903.html'
    }
    paper = @scraper.scrape_procedure(content, 'http://dipbt.bundestag.de/extrakt/ba/WP18/839/83903.html', extract)

    assert_equal(
      {
        legislative_term: 18,
        full_reference: "18/13660",
        reference: "13660",
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Neonazis als mögliche Quellen von Nachrichtendiensten',
        url: "http://dipbt.bundestag.de/dip21/btd/18/136/1813660.pdf",
        published_at: Date.parse('2017-09-29'),
        originators: {
          people: ["Martina Renner", "Dr. André Hahn"],
          parties: ["DIE LINKE"]
        },
        is_answer: true,
        answerers: {
          ministries: ["Bundesministerium des Innern"]
        },
        source_url: 'http://dipbt.bundestag.de/extrakt/ba/WP18/839/83903.html'
      }, paper)
  end

  def assert_answerer(paper_source, expected_ministry)
    content_xml = @scraper.extract_doc(Nokogiri::HTML(File.read(Rails.root.join(paper_source)).force_encoding('windows-1252')).to_s)
    answerers = @scraper.extract_procedure_xml(content_xml)[:answerers]
    assert_equal(expected_ministry, answerers[:ministries])
  end

  test 'extract ministry for 18/5644' do
    assert_answerer('test/fixtures/bt/detail_18_5644.html', ['Bundesministerium für Verkehr und digitale Infrastruktur'])
  end

  test 'extract ministry for 18/678' do
    assert_answerer('test/fixtures/bt/detail_18_678.html', ['Bundesministerium des Innern'])
  end

  test 'extract ministry for 18/5714' do
    assert_answerer('test/fixtures/bt/detail_18_5714.html', ['Bundeskanzleramt'])
  end
end