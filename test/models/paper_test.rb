require 'test_helper'

class PaperTest < ActiveSupport::TestCase
  test 'it fixes shuffled years in published_at date' do
    travel_to Date.parse('2015-10-10') do
      paper = Paper.new
      paper.published_at = Date.parse('2105-10-10')
      paper.run_callbacks(:validation)
      assert_equal Date.parse('2015-10-10'), paper.published_at
    end
  end
end
