require 'test_helper'

class HamburgPDFHasAnswerTest < ActiveSupport::TestCase
  ##
  # (Termin zur Beantwortung
  # gemäß 64 Absatz 1 GO LT:
  # 07.01.2015)
  test 'answered' do
    paper = Struct.new(:contents).new(
      "  und Antwort des Senats  \n" +
      " \n" +
      '  Betr.:'
    )
    assert HamburgPDFHasAnswerExtractor.new(paper).is_answer?
  end

  test 'not answered' do
    paper = Struct.new(:contents).new(
      '  Betr.:'
    )
    assert_not HamburgPDFHasAnswerExtractor.new(paper).is_answer?
  end
end