require 'test_helper'

class BodyControllerTest < ActionController::TestCase
  test 'should get show' do
    get :show, 'body' => 'bayern'
    assert_response :success
    assert_not_nil assigns(:body)
    assert_not_nil assigns(:terms)
  end
end
