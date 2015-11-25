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

  def assert_answerer(paper_source, expected_ministry)
    content_xml = @scraper.extract_doc(Nokogiri::HTML(File.read(Rails.root.join(paper_source)).force_encoding('windows-1252')).to_s)
    answerers = @scraper.extract_answerers_date_and_originators(content_xml)[:answerers]
    assert_equal(expected_ministry, answerers[:ministries])
  end

  test 'extract ministrie for 18/5644' do
    assert_answerer('test/fixtures/bundestag_detail_18_5644.html', ['Bundesministerium für Verkehr und digitale Infrastruktur'])
  end

  test 'extract ministrie for 18/678' do
    assert_answerer('test/fixtures/bundestag_detail_18_678.html', ['Bundesministerium des Innern'])
  end

  test 'extract ministrie for 18/5714' do
    assert_answerer('test/fixtures/bundestag_detail_18_5714.html', ['Bundeskanzleramt'])
  end
end