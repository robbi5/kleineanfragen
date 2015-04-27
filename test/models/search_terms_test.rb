require 'test_helper'

class SearchTermsTest < ActiveSupport::TestCase
  TEST_CASES = {
    'simple' => ['foo', 'foo', {}],
    'simple_field' => ['one:two', '', { 'one' => 'two' }],
    'quotes' => [%(foo:"quoted value"), '', { 'foo' => 'quoted value' }],
    'term_with_period' => ['1.5', '1.5', {}],
    'multiple_fields' => ['one:two three:four', '', { 'one' => 'two', 'three' => 'four' }],
    'int_parse' => ['id:123', '', { 'id' => 123 }],
    'int_parse_leading_letter' => ['id:a01', '', 'id' => 'a01'],
    'int_parse_leading_zero' => ['id:001', '', 'id' => '001'],
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

  test 'quoted' do
    terms = SearchTerms.new('something "hello world" else')
    assert_equal 'something "hello world" else', terms.query
    assert_equal 'something else', terms.unquoted
    assert_equal ['hello world'], terms.quoted
  end
end
