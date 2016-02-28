require 'test_helper'

class SearchControllerTest < ActionController::TestCase
  test 'should parse query' do
    query = 'single body:BY "quoted string" doctype:major'

    search = SearchController.parse_query(query)

    assert_equal 'single "quoted string"', search.term
    assert_equal({ body: ['BY'], doctype: ['major'] }, search.conditions)
  end

  test 'params_to_nice_query should support non-array param' do
    params = {
      body: 'BE'
    }
    query = SearchController.params_to_nice_query(params)
    assert_equal 'body:BE', query
  end

  test 'params_to_nice_query should support array param' do
    params = {
      body: ['BE', 'BY']
    }
    query = SearchController.params_to_nice_query(params)
    assert_equal 'body:BE,BY', query
  end
end
