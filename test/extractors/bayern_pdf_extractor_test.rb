require 'test_helper'

class BayernPDFExtractorTest < ActiveSupport::TestCase

  # testcases:
  ##
  # der Abgeordneten Ruth Müller SPD
  # des Abgeordneten Dr. Herbert Kränzlein SPD
  # der Abgeordneten Eva Gottstein FREIE WÄHLER
  test "one person, single line" do
    paper = Struct.new(:contents).new("der Abgeordneten Ruth Müller SPD")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 1, originators[:people].size
    assert_equal "Ruth Müller", originators[:people][0]
    assert_equal "SPD", originators[:party]
  end

  # der Abgeordneten Ulrike Gote\nBÜNDNIS 90/DIE GRÜNEN
  test "one person, newline between name and party" do
    paper = Struct.new(:contents).new("der Abgeordneten Ulrike Gote\nBÜNDNIS 90/DIE GRÜNEN")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 1, originators[:people].size
    assert_equal "Ulrike Gote", originators[:people][0]
    assert_equal "BÜNDNIS 90/DIE GRÜNEN", originators[:party]
  end

  # des Abgeordneten Prof. Dr. Peter Paul Gantzer SPD
  # der/des Abgeordneten Annette Karl SPD
  test "one person, broken" do
    paper = Struct.new(:contents).new("der/des Abgeordneten Annette Karl SPD")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 1, originators[:people].size
    assert_equal "Annette Karl", originators[:people][0]
    assert_equal "SPD", originators[:party]
  end

  # des Abgeordneten Prof. (Univ. Lima) Dr. Peter Bauer\nFREIE WÄHLER
  test "one person, special chars in name" do
    paper = Struct.new(:contents).new("des Abgeordneten Prof. (Univ. Lima) Dr. Peter Bauer\nFREIE WÄHLER")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 1, originators[:people].size
    assert_equal "Prof. (Univ. Lima) Dr. Peter Bauer", originators[:people][0]
    assert_equal "FREIE WÄHLER", originators[:party]
  end

  # der Abgeordneten Dr. Christian Magerl, Rosi Steinberger\nBÜNDNIS 90/DIE GRÜNEN
  test "two people, newline before party" do
    paper = Struct.new(:contents).new("der Abgeordneten Dr. Christian Magerl, Rosi Steinberger\nBÜNDNIS 90/DIE GRÜNEN")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 2, originators[:people].size
    assert_equal "Dr. Christian Magerl", originators[:people][0]
    assert_equal "Rosi Steinberger", originators[:people][1]
    assert_equal "BÜNDNIS 90/DIE GRÜNEN", originators[:party]
  end

  # der Abgeordneten Markus Ganserer, Martin Stümpfig, Christine Kamm BÜNDNIS 90/DIE GRÜNEN
  test "three people, no newline before party" do
    paper = Struct.new(:contents).new("der Abgeordneten Markus Ganserer, Martin Stümpfig, Christine Kamm BÜNDNIS 90/DIE GRÜNEN")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 3, originators[:people].size
    assert_equal "Markus Ganserer", originators[:people][0]
    assert_equal "Martin Stümpfig", originators[:people][1]
    assert_equal "Christine Kamm", originators[:people][2]
    assert_equal "BÜNDNIS 90/DIE GRÜNEN", originators[:party]
  end

  # der Abgeordneten Claudia Stamm und Thomas Mütze BÜNDNIS 90/DIE GRÜNEN
  test "two people, split with und" do
    paper = Struct.new(:contents).new("der Abgeordneten Claudia Stamm und Thomas Mütze BÜNDNIS 90/DIE GRÜNEN")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 2, originators[:people].size
    assert_equal "Claudia Stamm", originators[:people][0]
    assert_equal "Thomas Mütze", originators[:people][1]
    assert_equal "BÜNDNIS 90/DIE GRÜNEN", originators[:party]
  end

  # der Abgeordneten Herbert Woerlein, Dr. Linus Förster, Dr. Simone Strohmayr, Harald Güller SPD
  # der Abgeordneten Natascha Kohnen, Harry Scheuenstuhl, Annette Karl, Florian von Brunn, Susann Biedefeld, Johanna Werner-Muggendorfer, Doris Rauscher SPD
  test "seven people, split with comma" do
    paper = Struct.new(:contents).new("der Abgeordneten Natascha Kohnen, Harry Scheuenstuhl, Annette Karl, Florian von Brunn, Susann Biedefeld, Johanna Werner-Muggendorfer, Doris Rauscher SPD")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 7, originators[:people].size
    assert_equal "Natascha Kohnen", originators[:people][0]
    assert_equal "Harry Scheuenstuhl", originators[:people][1]
    assert_equal "Annette Karl", originators[:people][2]
    assert_equal "Florian von Brunn", originators[:people][3]
    assert_equal "Susann Biedefeld", originators[:people][4]
    assert_equal "Johanna Werner-Muggendorfer", originators[:people][5]
    assert_equal "Doris Rauscher", originators[:people][6]
    assert_equal "SPD", originators[:party]
  end

  # der Abgeordneten Markus Rinderspacher,\nArif Taşdelen SPD\nvom 17.03.2014
  test "two people, split with comma and newline, with trailing date" do
    paper = Struct.new(:contents).new("der Abgeordneten Markus Rinderspacher,\nArif Tasdelen SPD")#\nvom 17.03.2014

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 2, originators[:people].size
    assert_equal "Markus Rinderspacher", originators[:people][0]
    assert_equal "Arif Tasdelen", originators[:people][1]
    assert_equal "SPD", originators[:party]
  end

  # der Abgeordneten Dr. Christian Magerl, Rosi Steinberger\nBÜNDNIS 90/DIE GRÜNEN
  test "two people, newline in names" do
    paper = Struct.new(:contents).new("der Abgeordneten Dr. Christian Magerl,\nRosi Steinberger BÜNDNIS 90/DIE GRÜNEN")

    originators = BayernPDFExtractor.new(paper).extract

    assert_equal 2, originators[:people].size
    assert_equal "Dr. Christian Magerl", originators[:people][0]
    assert_equal "Rosi Steinberger", originators[:people][1]
    assert_equal "BÜNDNIS 90/DIE GRÜNEN", originators[:party]
  end
end