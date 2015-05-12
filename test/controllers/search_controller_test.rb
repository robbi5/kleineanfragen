require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test 'should parse query' do
    query = 'single body:BY "quoted string" doctype:major'

    search = SearchController.parse_query(query)

    assert_equal search.term, 'single "quoted string"'
    assert_equal search.conditions, body: ['BY'], doctype: ['major']
  end
end
