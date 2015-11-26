require 'test_helper'

class MeckPommPDFExtractorTest < ActiveSupport::TestCase
  test 'normal ministry' do
    paper = Struct.new(:contents).new(
      "Der Minister für Bildung, Wissenschaft und Kultur hat namens der Landesregierung die Kleine Anfrage mit\n\nSchreiben vom 16. November 2015 beantwortet."
    )

    answerers = MeckPommPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Bildung, Wissenschaft und Kultur', answerers[:ministries].first
  end

  test 'normal ministry 6/1332' do
    paper = Struct.new(:contents).new(
      "Die Ministerin für Arbeit, Gleichstellung und Soziales hat namens der Landesregierung die Kleine Anfrage mit\n\nSchreiben vom 27. November 2012 beantwortet."
    )

    answerers = MeckPommPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Arbeit, Gleichstellung und Soziales', answerers[:ministries].first
  end
end
