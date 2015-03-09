require 'test_helper'

class MvPDFHasAnswerTest < ActiveSupport::TestCase
  ##
  # (Termin zur Beantwortung
  # gemäß 64 Absatz 1 GO LT:
  # 07.01.2015)
  test 'has a due date attatched' do
    paper = Struct.new(:contents).new(
      " (Termin zur Beantwortung  \n" +
      "   gemäß 64 Absatz 1 GO LT:  \n" +
      "   \n" +
      '   07.01.2015)  '
    )
    assert_not MvPDFHasAnswerExtractor.new(paper).is_answer?
  end

  test 'no due date attatched' do
    paper = Struct.new(:contents).new(
      "Some\n" +
      "other\n" +
      'stuff'
    )
    assert MvPDFHasAnswerExtractor.new(paper).is_answer?
  end
end