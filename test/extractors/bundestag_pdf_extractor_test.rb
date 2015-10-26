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
  # auf die Kleine Anfrage der Abgeordneten Tom Koenigs, Luise Amtsberg, Omid
  # Nouripour, Uwe Kekeritz und der Fraktion der BÜNDNIS 90/DIE GRÜNEN
  test 'article before party' do
    paper = Struct.new(:contents).new(
      PREFIX + "Tom Koenigs, Luise Amtsberg, Omid\n" +
      "Nouripour, Uwe Kekeritz und der Fraktion der BÜNDNIS 90/DIE GRÜNEN\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 4, originators[:people].size
    assert_equal 1, originators[:parties].size
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

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Dr. Valerie Wilms, Dr. Harald Terpe,
  # Anja Hajduk, , weiterer Abgeordneter und der Fraktion BÜNDNIS 90/DIE GRÜNEN
  test 'duplicate comma, empty name' do
    paper = Struct.new(:contents).new(
      PREFIX + "Dr. Valerie Wilms, Dr. Harald Terpe,\n" +
      "Anja Hajduk, , weiterer Abgeordneter und der Fraktion BÜNDNIS 90/DIE GRÜNEN\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten der Martina Renner, Jan Korte,
  # Ulla Jelpke, weiterer Abgeordneter und der Fraktion DIE LINKE.
  test 'article before name' do
    paper = Struct.new(:contents).new(
      PREFIX + "der Martina Renner, Jan Korte,\n" +
      "Ulla Jelpke, weiterer Abgeordneter und der Fraktion DIE LINKE\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
    assert_equal 'Martina Renner', originators[:people].first
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Kleine Anfrage der Abgeordneten
  # Uwe Kekeritz, Claudia Roth (Augsburg), Omid Nouripour, weiterer Abgeordneter
  # und der Fraktion BÜNDNIS 90/DIE GRÜNEN
  test 'duplicate prefix long' do
    paper = Struct.new(:contents).new(
      PREFIX + "Kleine Anfrage der Abgeordneten\n" +
      "Uwe Kekeritz, Claudia Roth (Augsburg), Omid Nouripour, weiterer Abgeordneter\n" +
      "und der Fraktion BÜNDNIS 90/DIE GRÜNEN\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
    assert_equal 'Uwe Kekeritz', originators[:people].first
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten der Abgeordneten
  # Eva Bulling-Schröter, Caren Ley, Kerstin Kassner, weiterer
  # Abgeordneter und der Fraktion DIE LINKE.
  test 'duplicate prefix short' do
    paper = Struct.new(:contents).new(
      PREFIX + "der Abgeordneten\n" +
      "Eva Bulling-Schröter, Caren Ley, Kerstin Kassner, weiterer\n" +
      "Abgeordneter und der Fraktion DIE LINKE.\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
    assert_equal 'Eva Bulling-Schröter', originators[:people].first
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Abgeordneten Nicole Gohlke,
  # Sigrid Hupach, Klaus Ernst weiterer Abgeordneter und der Fraktion
  # DIE LINKE.
  test 'suffix without comma' do
    paper = Struct.new(:contents).new(
      PREFIX + "Nicole Gohlke,\n" +
      "Sigrid Hupach, Klaus Ernst weiterer Abgeordneter und der Fraktion\n" +
      "DIE LINKE\n")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
    assert_equal 'Klaus Ernst', originators[:people].last
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Fraktionen der CDU/CSU und SPD
  # – Drucksache...
  test 'parlamentary groups' do
    paper = Struct.new(:contents).new("Antwort\nder Bundesregierung\n\n" +
      "auf die Kleine Anfrage der Fraktionen der CDU/CSU und SPD\n– Drucksache")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 0, originators[:people].size
    assert_equal 2, originators[:parties].size
    assert_equal 'CDU/CSU', originators[:parties].first
    assert_equal 'SPD', originators[:parties].last
  end

  # Antwort
  # der Bundesregierung
  #
  # der Fraktionen der CDU/CSU und SPD
  # – Drucksache...
  test 'parlamentary groups with missing paper type' do
    paper = Struct.new(:contents).new("Antwort\nder Bundesregierung\n\n" +
      "der Fraktionen der CDU/CSU und SPD\n– Drucksache")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 0, originators[:people].size
    assert_equal 2, originators[:parties].size
    assert_equal 'CDU/CSU', originators[:parties].first
    assert_equal 'SPD', originators[:parties].last
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der Fraktionen CDU/CSU und SPD
  # – Drucksache...
  test 'parlamentary groups with missing der' do
    paper = Struct.new(:contents).new("Antwort\nder Bundesregierung\n\n" +
      "auf die Kleine Anfrage der Fraktionen CDU/CSU und SPD\n– Drucksache")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 0, originators[:people].size
    assert_equal 2, originators[:parties].size
    assert_equal 'CDU/CSU', originators[:parties].first
    assert_equal 'SPD', originators[:parties].last
  end

  # Antwort
  # der Bundesregierung
  #
  # auf die Kleine Anfrage der der Abgeordneten Dr. Kirsten Tackmann,
  # Birgit Menz, Caren Lay, weiterer Abgeordneter und
  # der Fraktion DIE LINKE betreffend
  # – Drucksache...
  test 'parlamentary group with additional suffix betreffend' do
    paper = Struct.new(:contents).new("Antwort\nder Bundesregierung\n\n" +
      "auf die Kleine Anfrage der der Abgeordneten Dr. Kirsten Tackmann,\n" +
      "Birgit Menz, Caren Lay, weiterer Abgeordneter und\n" +
      "der Fraktion DIE LINKE betreffend\n– Drucksache")

    originators = BundestagPDFExtractor.new(paper).extract_originators
    assert_equal 3, originators[:people].size
    assert_equal 1, originators[:parties].size
    assert_equal 'DIE LINKE', originators[:parties].first
  end
end