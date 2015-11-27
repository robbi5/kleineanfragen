require 'test_helper'

class BrandenburgPDFExtractorTest < ActiveSupport::TestCase
  # testcases:
  PREFIX = 'Namens der Landesregierung beantwortet '
  SUFFIX = ' die Kleine Anfrage wie folgt:'

  test 'normal ministry' do
    paper = Struct.new(:contents).new(
      PREFIX + 'die Ministerin für Wissenschaft, Forschung und Kultur' + SUFFIX)

    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Wissenschaft, Forschung und Kultur', answerers[:ministries].first
  end

  test 'newline in name' do
    paper = Struct.new(:contents).new(
      PREFIX + "die Ministerin für Arbeit, Soziales, Ge-\nsundheit, Frauen und Familie" + SUFFIX)

    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Arbeit, Soziales, Gesundheit, Frauen und Familie', answerers[:ministries].first
  end

  test 'newline and spaces in name' do
    paper = Struct.new(:contents).new(
      PREFIX + "der Minister des Innern und für Kommu-\n\nnales" + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium des Innern und für Kommunales', answerers[:ministries].first
  end

  test 'chef' do
    paper = Struct.new(:contents).new(
      PREFIX + 'der Chef der Staatskanzlei' + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Chef der Staatskanzlei', answerers[:ministries].first
  end

  test 'ministerium' do
    paper = Struct.new(:contents).new(
      PREFIX + 'das Ministerium der Finanzen' + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium der Finanzen', answerers[:ministries].first
  end

  test 'shorter suffix' do
    paper = Struct.new(:contents).new(
      PREFIX + 'der Minister der Finanzen die Anfrage wie folgt:')
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium der Finanzen', answerers[:ministries].first
  end

  test 'suffix without space' do
    paper = Struct.new(:contents).new(
      PREFIX + 'der Minister des Innern und für Kommunales die KleineAnfrage wie folgt:')
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium des Innern und für Kommunales', answerers[:ministries].first
  end

  test 'suffix lowercased' do
    paper = Struct.new(:contents).new(
      PREFIX + 'der Minister des Innern und für Kommunales die kleine Anfrage wie folgt:')
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium des Innern und für Kommunales', answerers[:ministries].first
  end

  test 'unnecessary suffix' do
    paper = Struct.new(:contents).new(
      PREFIX + 'der Minister für Ländliche Entwicklung, Umwelt und Landwirtschaft des Landes Brandenburg' + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Ländliche Entwicklung, Umwelt und Landwirtschaft', answerers[:ministries].first
  end

  test 'typo in Landesregierung' do
    paper = Struct.new(:contents).new(
      'Namens der Landregierung beantwortet der Minister der Justiz und für Europa und Verbraucherschutz' + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium der Justiz und für Europa und Verbraucherschutz', answerers[:ministries].first
  end

  test 'im namen' do
    paper = Struct.new(:contents).new(
      'Im Namen der Landesregierung beantwortet der Minister für Wirtschaft und Energie' + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Wirtschaft und Energie', answerers[:ministries].first
  end
end
