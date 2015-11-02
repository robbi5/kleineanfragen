require 'test_helper'

class BremenPDFExtractorTest < ActiveSupport::TestCase
  PREFIX = "9. Letzte Frage?\n\n"
  SUFFIX = "\n\n\n— 2 —\n\n\nD a z u\n\nAntwort des Senats vom"

  def paper_with_contents(contents)
    Struct.new(:contents, :doctype).new(contents, Paper::DOCTYPE_MINOR_INTERPELLATION)
  end

  test 'four people, one party' do
    paper = paper_with_contents(
      PREFIX + "Björn Fecker, Dirk Schmidtmann, Dr. Maike Schaefer,\n" + 
      "Dr. Matthias Güldner und Fraktion Bündnis 90/Die Grünen" + SUFFIX)

    originators = BremenPDFExtractor.new(paper).extract_originators

    assert_equal 4, originators[:people].size
    assert_equal 'Björn Fecker', originators[:people].first
    assert_equal 'Dirk Schmidtmann', originators[:people].second
    assert_equal 'Dr. Maike Schaefer', originators[:people].third
    assert_equal 'Dr. Matthias Güldner', originators[:people].fourth
  end

  # FIXME: not yet working
  #test 'two groups, six people, two parties' do
  #  paper = paper_with_contents(
  #    PREFIX + "Björn Fecker, Dirk Schmidtmann, Dr. Maike Schaefer,\n" +
  #    "Dr. Matthias Güldner und Fraktion Bündnis 90/Die Grünen\n\n" +
  #    "Sükrü Senkal,\nBjörn Tschöpe und Fraktion der SPD" + SUFFIX)
  #
  #  originators = BremenPDFExtractor.new(paper).extract_originators
  #
  #  assert_equal 6, originators[:people].size
  #  assert_equal 'Björn Fecker', originators[:people].first
  #  assert_equal 'Dirk Schmidtmann', originators[:people].second
  #  assert_equal 'Dr. Maike Schaefer', originators[:people].third
  #  assert_equal 'Dr. Matthias Güldner', originators[:people].fourth
  #  assert_equal 'Sükrü Senkal', originators[:people].fifth
  #  assert_equal 'Björn Tschöpe', originators[:people].sixth
  #end
end