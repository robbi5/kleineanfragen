require 'test_helper'

class BayernPDFExtractorAnswerersTest < ActiveSupport::TestCase
  def paper_with_answerer(answerer)
    Struct.new(:contents).new("Antwort\n#{answerer} vom")
  end

  test 'Staatsministeriums des Innern, für Bau und Verkehr' do
    paper = paper_with_answerer('des Staatsministeriums des Innern, für Bau und Verkehr')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
  end

  # contains soft hyphen between "Wis" "senschaft"
  test 'Staatsministeriums für Bildung und Kultus, Wissenschaft und Kunst' do
    paper = paper_with_answerer("des Staatsministeriums für Bildung und Kultus, Wis\u{AD}senschaft und Kunst")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst', answerers[:ministries].first
  end

  test 'Staatsministeriums für Umwelt und Verbraucherschutz' do
    paper = paper_with_answerer('des Staatsministeriums für Umwelt und Verbraucherschutz')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Umwelt und Verbraucherschutz', answerers[:ministries].first
  end

  # typo: d_a_s Staats...
  test 'Staatsministeriums für Gesundheit und Pflege' do
    paper = paper_with_answerer('das Staatsministeriums für Gesundheit und Pflege')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  test 'Bayerischen Staatskanzlei' do
    paper = paper_with_answerer('der Bayerischen Staatskanzlei')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Staatsministerin für Gesundheit und Pflege' do
    paper = paper_with_answerer('der Staatsministerin für Gesundheit und Pflege')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  test 'Staatsminister (missing s)' do
    paper = paper_with_answerer('des Staatsminister für Ernährung, Landwirtschaft und Forsten')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Ernährung, Landwirtschaft und Forsten', answerers[:ministries].first
  end

  test 'Leiterin Bayerische Staatskanzlei' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei\nStaatsministerin für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiters Bayerische Staatskanzlei und' do
    paper = paper_with_answerer("des Leiters der Bayerischen Staatskanzlei und\nStaatsministers für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiters Bayerische Staatskanzlei space' do
    paper = paper_with_answerer("des Leiters der Bayerischen Staatskanzlei \nStaatsminister für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiterin Bayerische Staatskanzlei Staatsministerin' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei Staatsministerin\n für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end
end