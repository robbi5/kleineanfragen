require 'test_helper'

class RheinlandPfalzPDFExtractorTest < ActiveSupport::TestCase
  def paper(type, contents)
    paper_with_title(type, contents, 'some title')
  end

  def paper_with_title(type, contents, title)
    Struct.new(:doctype, :contents, :title).new(type, contents, title)
  end

  test 'minor interpellation, one person' do
    c = "K l e i n e  A n f r a g e\n\n" +
        "des Abgeordneten Alexander Licht (CDU)\n\n" +
        "und\n\nA n t w o r t"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = RheinlandPfalzPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Alexander Licht', originators[:people].first
    assert_equal 'CDU', originators[:parties].first
  end

  test 'minor interpellation, one person, other things' do
    c = "K l e i n e  A n f r a g e\n\n" +
        "des Abgeordneten Alexander Licht (CDU)\n\n" +
        "und\n\nA n t w o r t\n\nund andere dinge, die dann hoffentlich\n\n" +
        "nicht drangetackert und ausgegeben werden"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = RheinlandPfalzPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Alexander Licht', originators[:people].first
    assert_equal 'CDU', originators[:parties].first
  end
end