require 'test_helper'

class OrganizationControllerTest < ActionController::TestCase
  test 'should get show' do
    paper(:paper_be_17_1000).originator_organizations << organization(:someparty)

    get :show, 'body' => 'berlin', 'organization' => 'someparty'
    assert_response :success
    assert_not_nil assigns(:body)
    assert_not_nil assigns(:organization)
    assert_not_nil assigns(:papers)
  end
end