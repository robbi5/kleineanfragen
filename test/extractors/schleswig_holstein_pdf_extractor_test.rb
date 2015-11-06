require 'test_helper'

class SchleswigHolsteinPDFExtractorTest < ActiveSupport::TestCase
  def paper_with_contents(contents)
    Struct.new(:contents).new(contents)
  end

  test 'one ministry (he)' do
    paper = paper_with_contents("und \n \n\nAntwort \n \nder Landesregierung - Innenminister ")

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Innenminister/in', answerers[:ministries].first
  end

  test 'one ministry (she)' do
    paper = paper_with_contents("und \n \n\nAntwort \n \nder Landesregierung - Ministerin für Bildung und Wissenschaft ")

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Minister/in für Bildung und Wissenschaft', answerers[:ministries].first
  end

  test 'no ministry' do
    paper = paper_with_contents("und \n \n\nAntwort \n \nder Landesregierung - \n \nVorbemerkung der Landesregierung:")

    answerers = SchleswigHolsteinPDFExtractor.new(paper).extract_answerers

    assert_nil answerers
  end
end
