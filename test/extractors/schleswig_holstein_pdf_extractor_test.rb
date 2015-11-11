require 'test_helper'

class SchleswigHolsteinPDFExtractorTest < ActiveSupport::TestCase
  PREFIX = "und \n \n\nAntwort \n \nder Landesregierung - "
  SUFFIX = " \n \n\n"

  def paper_with_contents(contents)
    Struct.new(:contents).new(contents)
  end

  test 'one ministry (he)' do
    paper = paper_with_contents(PREFIX + 'Innenminister' + SUFFIX)

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Innenminister/in', answerers[:ministries].first
  end

  test 'one ministry (she)' do
    paper = paper_with_contents(PREFIX + 'Ministerin für Bildung und Wissenschaft' + SUFFIX)

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister/in für Bildung und Wissenschaft', answerers[:ministries].first
  end

  test 'one ministry (generic)' do
    paper = paper_with_contents(PREFIX + 'Finanzministerium' + SUFFIX)

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Finanzministerium', answerers[:ministries].first
  end

  test 'one ministry with linebreak' do
    paper = paper_with_contents(PREFIX + "Minister für Energiewende, Landwirtschaft, Umwelt und \nländliche Räume" + SUFFIX)

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister/in für Energiewende, Landwirtschaft, Umwelt und ländliche Räume', answerers[:ministries].first
  end

  test 'no ministry' do
    paper = paper_with_contents(PREFIX + "\n \nVorbemerkung der Landesregierung:")

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_nil answerers
  end
end
