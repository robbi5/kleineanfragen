require 'test_helper'

class SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    @system_address = Mail::Address.new(Rails.configuration.x.email_from).address
  end

  test 'papers' do
    subscription = subscriptions(:subscription_active)
    papers = Paper.where(body: Body.find_by_state('BY')).limit(10).order(created_at: :desc).all
    mail = SubscriptionMailer.papers(subscription, papers)
    assert_equal 'Eine neue beantwortete Anfrage aus Bayern', mail.subject
    assert_equal ['test@example.org'], mail.to
    assert_equal [@system_address], mail.from
  end
end
