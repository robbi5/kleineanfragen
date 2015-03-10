require 'test_helper'

class SubscriptionControllerTest < ActionController::TestCase
  test "should get subscribe" do
    get :subscribe
    assert_response :success
  end

  test "should get unsubscribe" do
    get :unsubscribe
    assert_response :success
  end

end
