require 'test_helper'

class HamburgPDFHasAnswerTest < ActiveSupport::TestCase
  # testcases:

  ##
  # (Termin zur Beantwortung
  # gemäß 64 Absatz 1 GO LT:
  # 07.01.2015)
  test 'answered' do
    paper = Struct.new(:contents).new(
      "  und Antwort des Senats  \n" +
      " \n"+
      "  Betr.:"
    )
    answerAttatched = HamburgPDFHasAnswerExtractor.new(paper).is_answer?
    assert_equal true, answerAttatched
  end

  test 'not answered' do
    paper = Struct.new(:contents).new(
      "  Betr.:"
    )
    answerAttatched = HamburgPDFHasAnswerExtractor.new(paper).is_answer?
    assert_equal false, answerAttatched
  end

end