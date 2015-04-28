require 'test_helper'

class OptInControllerTest < ActionController::TestCase
  test 'should get confirm' do
    optin = opt_ins(:opt_in_unconfirmed)
    sub = subscriptions(:subscription_inactive)
    assert_not sub.active?, 'subscription should be inactive'

    get :confirm, 'subscription' => sub.to_param, 'confirmation_token' => '8224d55d9cfeb211aa067a08f97a0e5fd6250195'
    assert_response :success

    optin = OptIn.find(optin.id)
    assert optin.confirmed?, 'opt_in should now be active'
  end

  test 'should activate subscription' do
    sub = subscriptions(:subscription_inactive)
    assert_not sub.active?, 'subscription should be inactive'

    get :confirm, 'subscription' => sub.to_param, 'confirmation_token' => '8224d55d9cfeb211aa067a08f97a0e5fd6250195'
    assert_response :success

    sub = Subscription.find(sub.id)
    assert sub.active?, 'subscription should now be active'
  end

  test 'should fail if email is blacklisted' do
    sub = subscriptions(:subscription_inactive_blacklisted)

    get :confirm, 'subscription' => sub.to_param, 'confirmation_token' => '8224d55d9cfeb211aa067a08f97a0e5fd6250195'
    assert_response :unauthorized
  end

  test 'should get report' do
    sub = subscriptions(:subscription_inactive)

    get :report, 'subscription' => sub.to_param, 'confirmation_token' => '8224d55d9cfeb211aa067a08f97a0e5fd6250195'
    assert_response :success
  end

  test 'should cancel active subscriptions on report' do
    sub = subscriptions(:subscription_active)
    assert sub.active?, 'subscription should be active'

    get :report, 'subscription' => sub.to_param, 'confirmation_token' => '24fb72b3195aa101b88ac05ecbee060cacc7739d'
    assert_response :success

    sub = Subscription.find(sub.id)
    assert_not sub.active?, 'subscription should now be inactive'
    assert_not subscriptions(:subscription_active_too).active?, 'second subscription should now be inactive too'
  end
end
