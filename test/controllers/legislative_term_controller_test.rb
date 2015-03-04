require 'test_helper'

class LegislativeTermControllerTest < ActionController::TestCase
  test 'should get show' do
    get :show, 'body' => 'bayern', 'legislative_term' => 17
    assert_response :success
    assert_not_nil assigns(:body)
    assert_not_nil assigns(:legislative_term)
    assert_not_nil assigns(:papers)
  end
end
