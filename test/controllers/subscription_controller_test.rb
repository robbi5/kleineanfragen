require 'test_helper'

class SubscriptionControllerTest < ActionController::TestCase
  test 'should create inactive subscription and optin when email is unknown' do
    post :subscribe, params: { subscription: { email: 'fresh@example.org', subtype: :body, query: 'BE' } }
    assert_response :success

    sub = Subscription.find_by_email('fresh@example.org')
    assert_not sub.nil?, 'subscription should exist'
    assert_not sub.active?, 'subscription should not be active'

    optin = OptIn.find_by_email('fresh@example.org')
    assert_not optin.nil?, 'opt_in should exist'
  end

  test 'should create active subscription when optin is already done' do
    email = opt_ins(:opt_in_confirmed).email
    post :subscribe, params: { subscription: { email: email, subtype: :body, query: 'BE' } }
    assert_response :success

    sub = Subscription.find_by_email(email)
    assert_not sub.nil?, 'subscription should exist'
    assert sub.active?, 'subscription should be active'
  end

  test 'should fail if email is blacklisted' do
    email = email_blacklists(:blacklisted).email
    post :subscribe, params: { subscription: { email: email, subtype: :body, query: 'BE' } }
    assert_response :unauthorized
  end

  test 'should get unsubscribe' do
    sub = subscriptions(:subscription_active)
    get :unsubscribe, params: { 'subscription' => sub.to_param }
    assert_response :success

    assert_not Subscription.find(sub.id).active?, 'subscription should now be inactive'
  end
end
