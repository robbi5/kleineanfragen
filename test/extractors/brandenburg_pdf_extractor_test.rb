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
    assert_equal 'Ministerin für Wissenschaft, Forschung und Kultur', answerers[:ministries].first
  end

  test 'newline in name' do
    paper = Struct.new(:contents).new(
      PREFIX + "die Ministerin für Arbeit, Soziales, Ge-\nsundheit, Frauen und Familie" + SUFFIX)

    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerin für Arbeit, Soziales, Gesundheit, Frauen und Familie', answerers[:ministries].first
  end

  test 'newline and spaces in name' do
    paper = Struct.new(:contents).new(
      PREFIX + "der Minister des Innern und für Kommu-\n\nnales" + SUFFIX)
    answerers = BrandenburgPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister des Innern und für Kommunales', answerers[:ministries].first
  end
end