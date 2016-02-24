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
    assert_equal 'Teil einer Serie', paper.series_title
  end

  test 'it recognizes papers part of a series, round brackets in the middle' do
    paper = Paper.new
    paper.title = 'BER-Debakel (XXIV): Wie geht der "Reset" am BER vonstatten?'
    assert paper.part_of_series?
    assert_equal 'BER-Debakel', paper.series_title
  end

  test 'it recognizes papers part of a series, round brackets in the middle, dash' do
    paper = Paper.new
    paper.title = 'Staatsopernskandal (LXIII) - Wieder 600.000 Euro weniger? ...'
    assert paper.part_of_series?
    assert_equal 'Staatsopernskandal', paper.series_title
  end

  test 'it recognizes papers part of a series, no brackets in the middle, dash' do
    paper = Paper.new
    paper.title = '2. S-Bahn-Tunnel XII - "Regionalzüge im 2. Tunnel" - Infrastrukturkonzept'
    assert paper.part_of_series?
    assert_equal '2. S-Bahn-Tunnel', paper.series_title
  end

  test 'it recognizes papers that are not part of a series' do
    paper = Paper.new
    paper.title = 'Teil einer Serie (ABC)'
    assert_not paper.part_of_series?
  end

  test 'it recognizes papers that are not part of a series, round brackets in the middle' do
    paper = Paper.new
    paper.title = 'Serie (ABC): dummy text'
    assert_not paper.part_of_series?
  end

  test 'it recognizes papers that are not part of a series, round brackets in the middle, dash' do
    paper = Paper.new
    paper.title = 'Serie (ABC) - dummy text'
    assert_not paper.part_of_series?
  end
end
