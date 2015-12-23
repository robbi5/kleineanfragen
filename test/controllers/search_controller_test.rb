require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test 'should parse query' do
    query = 'single body:BY "quoted string" doctype:major'

    search = SearchController.parse_query(query)

    assert_equal 'single "quoted string"', search.term
    assert_equal({ body: ['BY'], doctype: ['major'] }, search.conditions)
  end
end
