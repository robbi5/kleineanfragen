require 'test_helper'

class OptInControllerTest < ActionController::TestCase
  test "should get confirm" do
    get :confirm
    assert_response :success
  end

  test "should get report" do
    get :report
    assert_response :success
  end

end
