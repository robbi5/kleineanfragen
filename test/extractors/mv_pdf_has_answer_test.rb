require 'test_helper'

class MvPDFHasAnswerTest < ActiveSupport::TestCase
  # testcases:

  ##
  # (Termin zur Beantwortung
  # gemäß 64 Absatz 1 GO LT:
  # 07.01.2015)
  test 'has a due date attatched' do
    paper = Struct.new(:contents).new(
      " (Termin zur Beantwortung  \n"+
      "   gemäß 64 Absatz 1 GO LT:  \n" +
      "   \n" +
      "   07.01.2015)  "
    )
    # do stuff
    answerAttatched = MvPDFHasAnswerExtractor.new(paper).is_answer?
    assert_equal false, answerAttatched
  end

  test 'no due date attatched' do
    paper = Struct.new(:contents).new(
      "Some\n" +
      "other\n" +
      "stuff")
    # do stuff
    answerAttatched = MvPDFHasAnswerExtractor.new(paper).is_answer?
    assert_equal true, answerAttatched
  end
end