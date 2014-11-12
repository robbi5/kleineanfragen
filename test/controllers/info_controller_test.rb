require 'test_helper'

class InfoControllerTest < ActionController::TestCase
  test "should get daten" do
    get :daten
    assert_response :success
  end

  test "should get kontakt" do
    get :kontakt
    assert_response :success
  end

end
