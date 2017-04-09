require 'test_helper'

class SaarlandScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = SaarlandScraper
    @html = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/sl/overview.html')))
  end

  test 'read json from resultpage' do
    entries = @scraper.extract_entries(@html)
    assert_equal 2786, entries.size
  end

  test 'create paper from table row' do
    entry = {
      "Titel"=>"Zustellungszeiten bei der Deutschen Post im Saarland",
      "Autor"=>"Landesregierung", "Dokumentname"=>"Aw15_2044.pdf",
      "URL"=>"/Drucksache/Aw15_2044.pdf", "Dokumentdatum"=>"19.12.2016",
      "Dokumentnummer"=>"15/2044"
    }
    paper = @scraper.extract_paper(entry)
    assert_equal(
      {
        legislative_term: '15',
        full_reference: '15/2044',
        reference: '2044',
        doctype: Paper::DOCTYPE_WRITTEN_INTERPELLATION,
        title: 'Zustellungszeiten bei der Deutschen Post im Saarland',
        url: 'https://www.landtag-saar.de/Drucksache/Aw15_2044.pdf',
        published_at: Date.parse('2016-12-19'),
        is_answer: true,
        answerers: { ministries: ['Landesregierung'] }
      }, paper)
  end

  test 'get date from entry' do
    entry = { 'Dokumentdatum' => '2015-01-12' }
    assert_equal Date.parse('2015-01-12'), @scraper.extract_date(entry)
  end

  test 'get title from entry' do
    entry = { 'Titel' => 'Abordnungen an Ministerien im Saarland  ' }
    assert_equal 'Abordnungen an Ministerien im Saarland', @scraper.extract_title(entry)
  end

  test 'is answer' do
    invalid_entry = { 'Dokumentname' => 'Xy15_1234.pdf' }
    entry = { 'Dokumentname' => 'Aw15_2345.pdf' }

    assert_not @scraper.extract_is_answer(invalid_entry)
    assert @scraper.extract_is_answer(entry)
  end

  test 'ignore invalid doctypes' do
    invalid_entry = { 'Dokumentname' => 'Xy15_1234.pdf' }
    entry = {
      "Titel"=>"Zustellungszeiten bei der Deutschen Post im Saarland",
      "Autor"=>"Landesregierung", "Dokumentname"=>"Aw15_2044.pdf",
      "URL"=>"/Drucksache/Aw15_2044.pdf", "Dokumentdatum"=>"19.12.2016",
      "Dokumentnummer"=>"15/2044"
    }

    assert_nil @scraper.extract_paper(invalid_entry)
    assert_not_equal nil, @scraper.extract_paper(entry)
  end
end