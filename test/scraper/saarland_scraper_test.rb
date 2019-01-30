require 'test_helper'

class SaarlandScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = SaarlandScraper
    @overview = File.read(Rails.root.join('test/fixtures/sl/get_search_results.json'))

    stub_request(:post, "https://www.landtag-saar.de/umbraco/aawSearchSurfaceController/SearchSurface/GetSearchResults/")
      .with(
        body: "{\"Filter\":{\"Periods\":[]},\"Pageination\":{\"Skip\":0,\"Take\":100},\"Sections\":{\"Print\":true,\"PlenaryProtocol\":false,\"Law\":false,\"PublicConsultation\":false},\"Sort\":{\"SortType\":0,\"SortValue\":0},\"OnlyTitle\":false,\"Value\":\"\",\"CurrentSearchTab\":1,\"KendoFilter\":null}"
      )
      .to_return(
        status: 200,
        body: @overview,
        headers: {
          "Content-Type": "application/json; charset=utf-8"
        }
      )
  end

  test '#scrape retrieves all results from saarland server url' do
    entries = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape

    assert_equal 22, entries.count
  end

  test '#scrape extracts title' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "Geldauflagen in Strafverfahren zugunsten gemeinnütziger Organisationen",
      entry[:title]
    )
  end

  test '#scrape extracts legislative_term' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "16",
      entry[:legislative_term]
    )
  end

  test '#scrape extracts reference' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "684",
      entry[:reference]
    )
  end

  test '#scrape extracts full_reference' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "16/684",
      entry[:full_reference]
    )
  end

  test '#scrape extracts doctype' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "written",
      entry[:doctype]
    )
  end

  test '#scrape extracts url' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "https://www.landtag-saar.de/file.ashx?FileId=12216&FileName=Aw16_0684.pdf",
      entry[:url]
    )
  end

  test '#scrape extracts published_at' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      "Thu, 13 Dec 2018".to_date,
      entry[:published_at]
    )
  end

  test '#scrape extracts is_answer' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      true,
      entry[:is_answer]
    )
  end

  test '#scrape assigns answerers' do
    entry = @scraper::Overview.new('SOME_LEGISLATIVE_TERM').scrape[6]

    assert_equal(
      {ministries: ["Landesregierung"]},
      entry[:answerers]
    )
  end

  test 'read json from resultpage' do
    entries = @scraper.extract_entries(@overview)
    assert_equal 100, entries.size
  end

  test 'create paper from table row' do
    entry = {
      "Title"=>"Zustellungszeiten bei der Deutschen Post im Saarland",
      "Autor"=>"Landesregierung",
      "FileName"=>"Aw15_2044.pdf",
      "FilePath"=>"/Drucksache/Aw15_2044.pdf",
      "PublicDate"=>"1547593200000",
      "DocumentNumber"=>"15/2044"
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
        published_at: Date.parse('2019-01-15'),
        is_answer: true,
        answerers: { ministries: ['Landesregierung'] }
      }, paper)
  end

  test 'get date from entry' do
    entry = { 'PublicDate' => '1547593200000' }
    assert_equal Date.parse('2019-01-15'), @scraper.extract_date(entry)
  end

  test 'get title from entry' do
    entry = { 'Title' => 'Abordnungen an Ministerien im Saarland  ' }
    assert_equal 'Abordnungen an Ministerien im Saarland', @scraper.extract_title(entry)
  end

  test 'is answer' do
    invalid_entry = { 'FileName' => 'Xy15_1234.pdf' }
    entry = { 'FileName' => 'Aw15_2345.pdf' }

    assert_not @scraper.extract_is_answer(invalid_entry)
    assert @scraper.extract_is_answer(entry)
  end

  test 'ignore invalid doctypes' do
    invalid_entry = { 'FileName' => 'Xy15_1234.pdf' }
    entry = {
      "Title"=>"Zustellungszeiten bei der Deutschen Post im Saarland",
      "Autor"=>"Landesregierung", "FileName"=>"Aw15_2044.pdf",
      "FilePath"=>"/Drucksache/Aw15_2044.pdf", "PublicDate"=>"1547593200000",
      "DocumentNumber"=>"15/2044"
    }

    assert_nil @scraper.extract_paper(invalid_entry)
    assert_not_equal nil, @scraper.extract_paper(entry)
  end
end