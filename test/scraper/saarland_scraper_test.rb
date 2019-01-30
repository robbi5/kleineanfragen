require 'test_helper'

class SaarlandScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = SaarlandScraper
    @overview = File.read(Rails.root.join('test/fixtures/sl/overview.html'))
    @html = Nokogiri::HTML(@overview)

    stub_request(:get, "https://www.landtag-saar.de/dokumente/drucksachen")
      .to_return(
        status: 200,
        body: @overview,
        headers: {
          "Content-Type": "text/html; charset=ISO-8859-1"
        }
      )
  end

  test '#scrape retrieves all results from saarland server url' do
    entries = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape

    assert_equal 725, entries.count
  end

  test '#scrape extracts title' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "Finanzielle Unterstützung von ungewollt kinderlos bleibenden Paaren " +
      "bei den Kosten einer künstlichen Befruchtung",
      entry[:title]
    )
  end

  test '#scrape extracts legislative_term' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "15",
      entry[:legislative_term]
    )
  end

  test '#scrape extracts reference' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "371",
      entry[:reference]
    )
  end

  test '#scrape extracts full_reference' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "15/371",
      entry[:full_reference]
    )
  end

  test '#scrape extracts doctype' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "written",
      entry[:doctype]
    )
  end

  test '#scrape extracts url' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "https://www.landtag-saar.de/Drucksache/Aw15_0371.pdf",
      entry[:url]
    )
  end

  test '#scrape extracts published_at' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      "Wed, 06 Mar 2013".to_date,
      entry[:published_at]
    )
  end

  test '#scrape extracts is_answer' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      true,
      entry[:is_answer]
    )
  end

  test '#scrape assigns answerers' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape.first

    assert_equal(
      {ministries: ["Landesregierung"]},
      entry[:answerers]
    )
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