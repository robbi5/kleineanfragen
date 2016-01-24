require 'test_helper'

class SearchTermsTest < ActiveSupport::TestCase
  TEST_CASES = {
    'simple' => ['foo', 'foo', {}],
    'simple_field' => ['one:two', '', { 'one' => 'two' }],
    'quotes' => [%(foo:"quoted value"), '', { 'foo' => 'quoted value' }],
    'term_with_period' => ['1.5', '1.5', {}],
    'multiple_fields' => ['one:two three:four', '', { 'one' => 'two', 'three' => 'four' }],
    'key_with_underscore' => ['under_score:foo', '', { 'under_score' => 'foo' }],
    'int_parse' => ['id:123', '', { 'id' => 123 }],
    'int_parse_leading_letter' => ['id:a01', '', 'id' => 'a01'],
    'int_parse_leading_zero' => ['id:001', '', 'id' => '001'],
    'int_parse_date' => ['date:2015-01-01', '', 'date' => '2015-01-01'],
    'int_parse_date_with_dots' => ['date:10.01.2015', '', 'date' => '10.01.2015'],
    'field_with_lower_than' => ['pages:<100', '', 'pages' => '<100'],
    'field_with_greater_than' => ['pages:>100', '', 'pages' => '>100'],
    'field_with_lower_than_equals' => ['pages:<=100', '', 'pages' => '<=100'],
    'field_with_greater_than_equals' => ['pages:>=100', '', 'pages' => '>=100'],
    'field_with_greater_than_equals_with_dots' => ['date:>=10.01.2015', '', 'date' => '>=10.01.2015'],
    'mixed_fields_terms' => ['one two:three four five:six', 'one four', { 'two' => 'three', 'five' => 'six' }],
    'term_in_quotes' => ['"hello world"', '"hello world"', {}],
    'term_with_comma' => ['hello,world', 'hello,world', {}]
  }

  TEST_CASES.each do |name, (input, query, parts)|
    test name do
      terms = SearchTerms.new(input)
      assert_equal query, terms.query
      assert_equal parts, terms.parts
    end
  end

  test 'whitelist' do
    terms = SearchTerms.new('hello world test:foo something:bad', ['test'])
    assert_equal 'hello world something:bad', terms.query
    assert_equal ({ 'test' => 'foo' }), terms.parts
  end
end
