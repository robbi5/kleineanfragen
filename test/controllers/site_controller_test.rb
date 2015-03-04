require 'test_helper'

class SiteControllerTest < ActionController::TestCase
  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:bodies)
    assert_not_nil assigns(:papers)
  end
end
