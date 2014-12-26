require 'test_helper'

class NamePartyExtractorTest < ActiveSupport::TestCase
  # Danny Freymark (CDU)
  test 'one person, one party, single line' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU)').extract

    assert_equal 1, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  # Danny Freymark (CDU), Alexander J. Herrmann (CDU)
  test 'two people, same party, single line' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU), Alexander J. Herrmann (CDU)').extract

    assert_equal 2, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 'Alexander J. Herrmann', pair[:people].last
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  # Danny Freymark (CDU) und Alexander J. Herrmann (CDU)
  test 'two people, same party, seperated by und' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU) und Alexander J. Herrmann (CDU)').extract

    assert_equal 2, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 'Alexander J. Herrmann', pair[:people].last
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end
end