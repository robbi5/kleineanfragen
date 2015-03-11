require 'test_helper'

class OptInMailerTest < ActionMailer::TestCase
  setup do
    @system_address = Mail::Address.new(Rails.configuration.x.email_from).address
    @support_address = Mail::Address.new(Rails.configuration.x.email_support).address
  end


  test 'opt_in' do
    opt_in = OptIn.new(email: 'test@example.org')
    subscription = Subscription.new
    mail = OptInMailer.opt_in(opt_in, subscription)
    assert_equal 'kleineAnfragen - E-Mail-Adresse bestätigen', mail.subject
    assert_equal ['test@example.org'], mail.to
    assert_equal [@system_address], mail.from
    # assert_match 'Hi', mail.body.encoded # FIXME: add things from email body
  end

  test 'report' do
    opt_in = OptIn.new(email: 'test@example.org')
    report = Report.new
    mail = OptInMailer.report(opt_in, report)
    assert_equal "[report] #{opt_in.email} ist nun auf der E-Mail-Blacklist", mail.subject
    assert_equal [@support_address], mail.to
    assert_equal [@system_address], mail.from
    # assert_match 'Hi', mail.body.encoded # FIXME: add things from email body
  end
end
