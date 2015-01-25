require 'test_helper'

class BundestagPDFExtractorTest < ActiveSupport::TestCase
  # testcases:
  PREFIX = "Antwort\nder Bundesregierung\n\nauf die Kleine Anfrage der Abgeordneten "

  ##
  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Oliver Krischer, Bärbel Höhn, Britta
  # Haßelmann, weiterer Abgeordneter und der Fraktion BÜNDNIS 90/DIE GRÜNEN.
  test 'three people, two lines' do
    paper = Struct.new(:contents).new(
      PREFIX + "Oliver Krischer, Bärbel Höhn, Britta\n" +
      "Haßelmann, weiterer Abgeordneter und der Fraktion BÜNDNIS 90/DIE GRÜNEN\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Oliver Krischer', originators[:people].first
    assert_equal 'Bärbel Höhn', originators[:people].second
    assert_equal 'Britta Haßelmann', originators[:people].third
    assert_equal 'BÜNDNIS 90/DIE GRÜNEN', originators[:parties].first
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Beate Müller-Gemmeke, Dr. Wolfgang
  # Strengmann-Kuhn, Markus Kurth, weiterer Abgeordneter und der Fraktion
  # BÜNDNIS 90/DIE GRÜNEN
  test 'three people, doppelnamen, newline before party' do
    paper = Struct.new(:contents).new(
      PREFIX + "Beate Müller-Gemmeke, Dr. Wolfgang\n" +
      "Strengmann-Kuhn, Markus Kurth, weiterer Abgeordneter und der Fraktion\n" +
      "BÜNDNIS 90/DIE GRÜNEN\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators

    assert_equal 3, originators[:people].size
    assert_equal 'Beate Müller-Gemmeke', originators[:people].first
    assert_equal 'Dr. Wolfgang Strengmann-Kuhn', originators[:people].second
    assert_equal 'Markus Kurth', originators[:people].third
    assert_equal 'BÜNDNIS 90/DIE GRÜNEN', originators[:parties].first
  end


  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Stephan Mayer (Altötting),
  # Armin Schuster (Weil am Rhein), Marian Wendt, weiterer Abgeordneter und
  # der Fraktion der CDU/CSU
  # sowie der Abgeordneten Dr. Lars Castellucci, Gabriele Fograscher, Uli Grötsch,
  # weiterer Abgeordneter und der Fraktion der SPD
  test 'two groups, six people, two parties' do
    paper = Struct.new(:contents).new(
      PREFIX + "Stephan Mayer (Altötting),\n" +
      "Armin Schuster (Weil am Rhein), Marian Wendt, weiterer Abgeordneter und\n" +
      "der Fraktion der CDU/CSU\n" +
      "sowie der Abgeordneten Dr. Lars Castellucci, Gabriele Fograscher, Uli Grötsch,\n" +
      "weiterer Abgeordneter und der Fraktion der SPD\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 6, originators[:people].size
    assert_equal 'Stephan Mayer', originators[:people].first
    assert_equal 2, originators[:parties].size
  end
end