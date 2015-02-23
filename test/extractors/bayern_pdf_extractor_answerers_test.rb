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
end