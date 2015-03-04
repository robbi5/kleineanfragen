require 'test_helper'

class MinistryControllerTest < ActionController::TestCase
  test 'should get show' do
    get :show, 'body' => 'bayern', 'ministry' => 'staatsministerium-fuer-umwelt-und-verbraucherschutz'
    assert_response :success
    assert_not_nil assigns(:body)
    assert_not_nil assigns(:ministry)
    assert_not_nil assigns(:papers)
  end
end
