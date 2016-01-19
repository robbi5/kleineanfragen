require 'test_helper'

class EsQueryParserTest < ActiveSupport::TestCase
  CONVERT_RANGE_TEST_CASES = {
    'number as string' => ['1', 1],
    'number' => [1, 1],
    'gt 1' => ['>1', { gt: 1 }],
    'lt 1' => ['<1', { lt: 1 }],
    'gte 1' => ['>=1', { gte: 1 }],
    'lte 1' => ['<=1', { lte: 1 }],
    'nothing' => ['', nil],
    'not a number' => ['e', nil]
  }

  CONVERT_RANGE_TEST_CASES.each do |name, (input, output)|
    test name do
      range = EsQueryParser.convert_range(input)
      assert_equal output, range
    end
  end
end
