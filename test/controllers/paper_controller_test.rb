require 'test_helper'

class PaperControllerTest < ActionController::TestCase
  test 'should get show' do
    get :show, params: { 'body' => 'bayern', 'legislative_term' => 17, 'paper' => '2000-noch-nicht-erfolgter-bericht-zur-aufklaerung-ueber-das-ausmass-und-die-handhabung-des-einsatzes-derivativer' }
    assert_response :success
    assert_not_nil assigns(:body)
    assert_not_nil assigns(:legislative_term)
    assert_not_nil assigns(:paper)
  end

  test 'should redirect if slug is wrong' do
    get :show, params: { 'body' => 'bayern', 'legislative_term' => 17, 'paper' => '2000-something' }
    assert_redirected_to paper_path(assigns(:body), assigns(:legislative_term), assigns(:paper))
  end

  test 'should redirect if paper redirect exists' do
    pr = paper_redirects(:one)
    get :show, params: { 'body' => 'hessen', 'legislative_term' => 19, 'paper' => '1874-something' }
    assert_redirected_to paper_path(pr.paper.body, pr.paper.legislative_term, pr.paper)
  end
end
