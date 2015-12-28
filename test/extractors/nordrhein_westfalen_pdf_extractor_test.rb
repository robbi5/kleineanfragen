require 'test_helper'

class NordrheinWestfalenPDFExtractorTest < ActiveSupport::TestCase
  PREFIX = "Antwort \n \nder Landesregierung \n\nauf die Kleine Anfrage 1234 vom 12. März 2015 \n"
  SUFFIX = "\nDrucksache 16/1234"

  def paper_with_contents(contents)
    Struct.new(:contents).new(contents)
  end

  test 'one person, one party' do
    paper = paper_with_contents(PREFIX + 'des Abgeordneten Werner Lohn   CDU' + SUFFIX)

    originators = NordrheinWestfalenPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Werner Lohn', originators[:people].first
    assert_equal 1, originators[:parties].size
    assert_equal 'CDU', originators[:parties].first
  end

  test 'three people, one party' do
    paper = paper_with_contents(PREFIX + 'der Abgeordneten Birgit Rydlewski, Frank Herrmann und Daniel Schwerd   PIRATEN' + SUFFIX)

    originators = NordrheinWestfalenPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Birgit Rydlewski', originators[:people].first
    assert_equal 'Frank Herrmann', originators[:people].second
    assert_equal 'Daniel Schwerd', originators[:people].third
    assert_equal 1, originators[:parties].size
    assert_equal 'PIRATEN', originators[:parties].first
  end
end