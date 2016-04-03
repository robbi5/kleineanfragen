require 'test_helper'

class SachsenExportScraperTest < ActiveSupport::TestCase
  def setup
    @scraper = SachsenExportScraper
    @file = File.open(Rails.root.join('test/fixtures/sn/klanfrde_2016-02-29-short.xml'))
  end

  test 'it uses yesterdays date for the export filename' do
    travel_to Date.parse('2016-04-03') do
      assert_equal 'KlAnfrDe_2016-04-02', @scraper.export_filename
    end
  end

  test 'parse all papers from excerpt' do
    papers = []
    SachsenExportScraper::Overview.read(@file, 6) do |paper|
      papers << paper
    end

    assert_equal 3, papers.size
    assert_equal(
      {
        legislative_term: 6,
        reference: '758',
        full_reference: '6/758',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Treffen Asylpolitik Bürgermeisterinnen und Bürgermeister',
        published_at: Date.parse('2015-03-03'),
        is_answer: true,
        originators: {
          people: ['Petra Zais'],
          parties: ['GRÜNE']
        },
        answerers: {
          ministries: ['Staatskanzlei']
        }
      }, papers.first)

    assert_equal(
      {
        legislative_term: 6,
        reference: '762',
        full_reference: '6/762',
        doctype: Paper::DOCTYPE_MAJOR_INTERPELLATION,
        title: '"So geht sächsisch." - Standortkampagne für den Freistaat Sachsen',
        published_at: Date.parse('2015-03-30'),
        is_answer: true,
        originators: {
          people: [],
          parties: ['DIE LINKE']
        },
        answerers: {
          ministries: ['Staatskanzlei']
        }
      }, papers.second)

    assert_equal(
      {
        legislative_term: 6,
        reference: '4388',
        full_reference: '6/4388',
        doctype: Paper::DOCTYPE_MINOR_INTERPELLATION,
        title: 'Personalausstattung der sächsischen Arbeitsschutzverwaltung',
        published_at: nil,
        is_answer: false,
        originators: {
          people: ['Nico Brünler'],
          parties: ['DIE LINKE']
        },
        answerers: {
          ministries: []
        }
      }, papers.third)
  end

end