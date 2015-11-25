require 'test_helper'

class ExtractTextFromPaperJobTest < ActiveSupport::TestCase
  test 'keep hyphen at wordwrap if it is a name' do
    text = "Beate Walter-\n" +
           "Rosenheimer"
    # result = "Beate Walter-Rosenheimer\n"
    result_text = ExtractTextFromPaperJob.clean_text(text)
    assert_equal text, result_text
  end

  test 'remove hyphen at wordwrap' do
    text = "be-\n" +
           "pflanzt"
    expected = "bepflanzt\n"
    result_text = ExtractTextFromPaperJob.clean_text(text)
    assert_equal expected, result_text
  end
end
