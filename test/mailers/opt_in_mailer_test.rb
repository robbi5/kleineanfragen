require 'test_helper'

class OptInMailerTest < ActionMailer::TestCase
  test "opt_in" do
    mail = OptInMailer.opt_in
    assert_equal "Opt in", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

  test "report" do
    mail = OptInMailer.report
    assert_equal "Report", mail.subject
    assert_equal ["to@example.org"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Hi", mail.body.encoded
  end

end
