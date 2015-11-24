require 'test_helper'

class BrandenburgScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = BrandenburgLandtagScraper
    @overview = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/brandenburg_scraper_overview.html')).force_encoding('windows-1252'))
    @detail = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/brandenburg_scraper_detail.html')).force_encoding('windows-1252'))
  end

  # webpage states that it shows 671 results but actually displays 482
  test 'extract overview items' do
    body = @scraper.extract_body(@overview)
    items = @scraper.extract_overview_items(body)
    assert_equal 482, items.length
  end

  test 'extract title from item row' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    title = @scraper.extract_title(item)
    assert_equal 'Umzug der Schulaufsicht von Perleberg nach Neuruppin', title
  end

  test 'extract originators' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    meta = @scraper.extract_meta(item)
    originators = @scraper.extract_originators(meta.text, Paper::DOCTYPE_MINOR_INTERPELLATION)
    assert_equal 'Gordon Hoffmann', originators[:people][0]
    assert_equal 'CDU', originators[:parties][0]
  end

  test 'extract published_at' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    meta = @scraper.extract_meta(item)
    published_at = @scraper.extract_published_at(meta.text)
    assert_equal Date.parse('2015-02-13'), published_at
  end

  test 'extract overview paper' do
    body = @scraper.extract_body(@overview)
    item = @scraper.extract_overview_items(body).last
    paper = @scraper.extract_paper_overview(item)

    assert_equal(
      {
        legislative_term: '6',
      full_reference: '6/39',
      reference: '39',
      url: 'http://www.parldok.brandenburg.de/parladoku/w6/drs/ab_0001/39.pdf',
      published_at: Date.parse('2014-11-03'),
      is_answer: true
    }, paper)
  end

  test 'extract detail paper' do
    body = @scraper.extract_body(@detail)
    item = @scraper.extract_detail_item(body)
    paper = @scraper.extract_detail_paper(item)

    assert_equal(
      {
        legislative_term: '6',
      full_reference: '6/618',
      reference: '618',
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: 'Umzug der Schulaufsicht von Perleberg nach Neuruppin',
      url: 'http://www.parldok.brandenburg.de/parladoku/w6/drs/ab_0600/618.pdf',
      published_at: Date.parse('2015-02-13'),
      originators: {
      people: ['Gordon Hoffmann'],
      parties: ['CDU']
    },
      is_answer: true
    }, paper)
  end

  test 'extract major interpellation detail paper 614' do
    detail = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/brandenburg_scraper_detail_614.html')).force_encoding('windows-1252'))
    body = @scraper.extract_body(detail)
    item = @scraper.extract_detail_item(body)
    paper = @scraper.extract_detail_paper(item)

    assert_equal(
      {
        legislative_term: '6',
      full_reference: '6/614',
      reference: '614',
      doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
      title: 'Situation von Flüchtlingen und Asylbewerbern in Brandenburg',
      url: 'http://www.parldok.brandenburg.de/parladoku/w6/drs/ab_0600/614.pdf',
      published_at: Date.parse('2015-02-12'),
      originators: {
      people: [],
      parties: ['CDU']
    },
      is_answer: true
    }, paper)
  end

  test 'multiple parties on major interpellations' do
    meta = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
                  GrAnfr 10   (SPD,DIE LINKE)  13.01.2015 Drs
                  6/420 (1 S.)Antw   (LReg)  13.02.2015 Drs
                  6/618 (3 S.)
    END
    assert_equal(
      {
        people: [],
      parties: ['SPD', 'DIE LINKE']
    }, @scraper.extract_originators(meta, Paper::DOCTYPE_MAJOR_INTERPELLATION)
    )
  end

  test 'multiple people on minor interpellation' do
    meta = <<-END.gsub(/^ {6}/, '').sub(/\n$/, '')
              KlAnfr 179   Gordon Freeman (CDU), Black Widow (DIE LINKE)  13.01.2015 Drs
              6/420 (1 S.)Antw   (LReg)  13.02.2015 Drs
              6/618 (3 S.)
    END
    assert_equal(
      {
        people: ['Gordon Freeman', 'Black Widow'],
      parties: ['CDU', 'DIE LINKE']
    }, @scraper.extract_originators(meta, Paper::DOCTYPE_MINOR_INTERPELLATION)
    )
  end

  test 'test extract details #33' do
    detail = Nokogiri::HTML(File.read(Rails.root.join('test/fixtures/brandenburg_scraper_detail_6_2973.html')).force_encoding('windows-1252'))
    body = @scraper.extract_body(detail)
    item = @scraper.extract_detail_item(body)
    paper = @scraper.extract_detail_paper(item)

    assert_equal(
      {
        legislative_term: '6',
      full_reference: '6/2973',
      reference: '2973',
      doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
      title: 'Unterbringung von Flüchtlingen in den Landkreisen Brandenburgs, Stand 30.09.2015',
      url: 'http://www.parldok.brandenburg.de/parladoku/w6/drs/ab_2900/2973.pdf',
      published_at: Date.parse('2015-11-12'),
      originators: {
      people: ['Andrea Johlige'],
      parties: ['DIE LINKE']
    },
      is_answer: true
    }, paper)
  end
end