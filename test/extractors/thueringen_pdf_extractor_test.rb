require 'test_helper'

class ThueringenPDFExtractorTest < ActiveSupport::TestCase
  def paper_with_contents(contents)
    Struct.new(:contents).new(contents)
  end

  test 'one party' do
    paper = paper_with_contents("K\n l e i n e  A n f r a g e\n\ndes Abgeordneten Kießling (AfD)\nund\n\nA n t w o r t")

    originators = ThueringenPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:parties].size
    assert_equal 'AfD', originators[:parties].first
  end
end
