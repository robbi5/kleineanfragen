require 'test_helper'

class EsQueryParserTest < ActiveSupport::TestCase
  CONVERT_RANGE_TEST_CASES = {
    'number as string' => ['1', 1],
    'number' => [1, 1],
    'gt 1' => ['>1', { gt: 1 }],
    'lt 1' => ['<1', { lt: 1 }],
    'gte 1' => ['>=1', { gte: 1 }],
    'lte 1' => ['<=1', { lte: 1 }],
    'range incl 1 2' => ['[1 TO 2]', { gte: 1, lte: 2 }],
    'range excl 1 2' => ['{1 TO 2}', { gt: 1, lt: 2 }],
    'nothing' => ['', nil],
    'not a number' => ['e', nil]
  }

  CONVERT_RANGE_TEST_CASES.each do |name, (input, output)|
    test "convert range #{name}" do
      range = EsQueryParser.convert_range(input)
      assert_equal output, range
    end
  end

  CONVERT_DATE_RANGE_TEST_CASES = {
    'simple iso8601 date' => ['2015-12-01', '2015-12-01'],
    'year' => ['2015', '2015'],
    'gt iso8601' => ['>2015-12-01', { gt: '2015-12-01' }],
    'lt iso8601' => ['<2015-12-01', { lt: '2015-12-01' }],
    'gte iso8601' => ['>=2015-12-01', { gte: '2015-12-01' }],
    'lte iso8601' => ['<=2015-12-01', { lte: '2015-12-01' }],
    'range incl iso8601' => ['[2015-01-01 TO 2015-12-31]', { gte: '2015-01-01', lte: '2015-12-31' }],
    'range excl iso8601' => ['{2015-01-01 TO 2015-12-31}', { gt: '2015-01-01', lt: '2015-12-31' }],
    'nothing' => ['', nil],
    'not a number' => ['e', nil],
    'not a year' => ['99999', nil],
    'not a date' => ['2015-30-40', nil]
  }

  CONVERT_DATE_RANGE_TEST_CASES.each do |name, (input, output)|
    test "convert date #{name}" do
      range = EsQueryParser.convert_date_range(input)
      assert_equal output, range
    end
  end

  test 'return_range' do
    assert_equal ({ gte: 1, lte: 2 }), EsQueryParser.return_range(type: :range, range: :inclusive, value: [1, 2])
    assert_equal ({ gt: 1, lt: 2 }), EsQueryParser.return_range(type: :range, range: :exclusive, value: [1, 2])
  end
end
