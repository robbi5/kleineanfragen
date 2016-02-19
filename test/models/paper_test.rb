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

  test 'it recognizes papers part of a series' do
    paper = Paper.new
    paper.title = 'Teil einer Serie (III)'
    assert paper.part_of_series?
  end

  test 'it recognizes papers part of a series, other format' do
    paper = Paper.new
    paper.title = 'BER-Debakel (XXIV): Wie geht der "Reset" am BER vonstatten?'
    assert paper.part_of_series?
  end

  test 'it recognizes papers that are not part of a series' do
    paper = Paper.new
    paper.title = 'Teil einer Serie (abc)'
    assert_not paper.part_of_series?
  end
  test 'it recognizes papers that are not part of a series, other format' do
    paper = Paper.new
    paper.title = 'Serie (abc): dummy text'
    assert_not paper.part_of_series?
  end
end
