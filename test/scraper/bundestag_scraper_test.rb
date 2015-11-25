require 'test_helper'

class BundestagScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BundestagScraper
    @content = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/bundestag_detail.html')).force_encoding('windows-1252')).to_s
    @content_xml = @scraper.extract_doc(@content)
  end

  test 'extract details' do
    assert_equal(Paper::DOCTYPE_MINOR_INTERPELLATION, @scraper.extract_doctype(@content_xml))
    assert_equal('Beantwortet', @scraper.extract_status(@content_xml))
    assert_equal('Einsatz von Flugzeugen, Hubschraubern und Drohnen beim G7-Gipfel in Bayern', @scraper.extract_title(@content_xml))
  end

  def assert_answerer(expected_ministry, paper_source)
    content_xml = @scraper.extract_doc(Nokogiri::HTML(File.read(Rails.root.join(paper_source)).force_encoding('windows-1252')).to_s)
    answerers = @scraper.extract_answerers_date_and_originators(content_xml).first
    assert_equal(expected_ministry, answerers[:ministries])
  end

  test 'extract different people and ministries' do
    paper_source = 'test/fixtures/bundestag_detail.html'
    expected_ministry = ['Bundeskanzleramt']
    assert_answerer(expected_ministry, paper_source)

    paper_source = 'test/fixtures/bundestag_detail_18_5644.html'
    expected_ministry = ['Bundesministerium für Verkehr und digitale Infrastruktur']
    assert_answerer(expected_ministry, paper_source)

    paper_source = 'test/fixtures/bundestag_detail_18_678.html'
    expected_ministry = ['Bundesministerium des Innern']
    assert_answerer(expected_ministry, paper_source)

    paper_source = 'test/fixtures/bundestag_detail_18_5714.html'
    expected_ministry = ['Bundeskanzleramt']
    assert_answerer(expected_ministry, paper_source)
  end
end