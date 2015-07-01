require 'test_helper'

class HessenPDFExtractorTest < ActiveSupport::TestCase
  # testcases:
  PREFIX = "\nund  \n\nAntwort  \n\n "
  SUFFIX = "\n \n \n Vorbemerkung des Fragestellers: "

  test 'normal ministry' do
    paper = Struct.new(:contents).new(
      PREFIX + 'des Ministers der Finanzen' + SUFFIX)

    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister der Finanzen', answerers[:ministries].first
  end

  test 'suffix: die' do
    paper = Struct.new(:contents).new(
      PREFIX + "des Kultusministers  \n \n \nDie Kleine Anfrage beantworte ich wie folgt:")

    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Kultusminister', answerers[:ministries].first
  end

  test 'suffix: im einvernehmen' do
    paper = Struct.new(:contents).new(
      PREFIX + "der Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des \n\nLandes Hessen beim Bund \n \n \n Im Einvernehmen mit dem Kultusminister,")
    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerin für Bundes- und Europaangelegenheiten und Bevollmächtigten des Landes Hessen beim Bund', answerers[:ministries].first
  end

  test 'suffix: other words' do
    paper = Struct.new(:contents).new(
      PREFIX + "des Ministers der Finanzen \n \n \n \nNach dem Erlass")
    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister der Finanzen', answerers[:ministries].first
  end

  test 'suffix: less newlines' do
    paper = Struct.new(:contents).new(
      PREFIX + "des Ministers für Soziales und Integration \n\nVorbemerkung des Fragestellers: ")

    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister für Soziales und Integration', answerers[:ministries].first
  end

  test 'suffix: der Fragesteller' do
    paper = Struct.new(:contents).new(
      PREFIX + "des Ministers für Soziales und Integration \nder Fragesteller: " + SUFFIX)
    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister für Soziales und Integration', answerers[:ministries].first
  end

  test 'major interpellation' do
    paper = Struct.new(:contents).new(
      "Antwort \n\nder Landesregierung \n\nauf die Große Anfrage der Abg. G")
    answerers = HessenPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Landesregierung', answerers[:ministries].first
  end
end