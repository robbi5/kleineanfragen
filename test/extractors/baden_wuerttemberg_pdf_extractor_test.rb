require 'test_helper'

class BadenWuerttembergPDFExtractorTest < ActiveSupport::TestCase
  def paper(type, contents)
    Struct.new(:doctype, :contents).new(type, contents)
  end

  test 'minor interpellation, one person' do
    c = "\n\nKleine Anfrage\n\ndes Abg. Dr. Hans-Ulrich Rülke FDP/DVP\n\n" +
        "und\n\nAntwort\n\ndes Ministeriums für Ländlichen Raum\n\nund Verbraucherschutz\n\n"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Dr. Hans-Ulrich Rülke', originators[:people].first
    assert_equal 'FDP/DVP', originators[:parties].first
  end

  test 'minor interpellation, three people, one with a 3 letter surname' do
    c = "\n\nKleine Anfrage\n\nder Abg. Helmut Rau, Volker Schebesta und Willi Stächele CDU\n" +
        "und\nAntwort\n"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Helmut Rau', originators[:people].first
    assert_equal 'Volker Schebesta', originators[:people].second
    assert_equal 'Willi Stächele', originators[:people].third
    assert_equal 1, originators[:parties].size
    assert_equal 'CDU', originators[:parties].first
  end

  test 'minor interpellation, three people, two parties' do
    c = "\n\nKleine Anfrage\n\nder Abg. Alexander Salomon und Dr. Gisela Splett GRÜNE\n" +
        "und des Abg. Johannes Stober SPD\n\n" +
        "und\n\nAntwort"
    paper = paper(Paper::DOCTYPE_MINOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Alexander Salomon', originators[:people].first
    assert_equal 'Dr. Gisela Splett', originators[:people].second
    assert_equal 'Johannes Stober', originators[:people].third
    assert_equal 2, originators[:parties].size
    assert_equal 'GRÜNE', originators[:parties].first
    assert_equal 'SPD', originators[:parties].second
  end

  test 'major interpellation, one party' do
    c = "\n\nGroße Anfrage \n\nder Fraktion der FDP/DVP\n\n"
    paper = paper(Paper::DOCTYPE_MAJOR_INTERPELLATION, c)

    originators = BadenWuerttembergPDFExtractor.new(paper).extract_originators

    assert_not_nil originators, 'originators should not be nil'
    assert_equal 1, originators[:parties].size
    assert_equal 'FDP/DVP', originators[:parties].first
  end
end