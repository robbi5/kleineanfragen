require 'test_helper'

class BayernPDFExtractorAnswerersTest < ActiveSupport::TestCase
  def paper_with_answerer(answerer, wrap: true)
    answerer = "Antwort\n#{answerer} vom" if wrap
    Struct.new(:contents).new(answerer)
  end

  test 'Staatsministeriums des Innern, für Bau und Verkehr' do
    paper = paper_with_answerer('des Staatsministeriums des Innern, für Bau und Verkehr')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
  end

  # contains soft hyphen between "Wis" "senschaft"
  test 'Staatsministeriums für Bildung und Kultus, Wissenschaft und Kunst' do
    paper = paper_with_answerer("des Staatsministeriums für Bildung und Kultus, Wis\u{AD}senschaft und Kunst")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst', answerers[:ministries].first
  end

  test 'Staatsministeriums für Umwelt und Verbraucherschutz' do
    paper = paper_with_answerer('des Staatsministeriums für Umwelt und Verbraucherschutz')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Umwelt und Verbraucherschutz', answerers[:ministries].first
  end

  test 'Staatsministeriums des(newline)Innern, für Bau und Verkehr' do
    paper = paper_with_answerer("des Staatsministeriums des\nInnern, für Bau und Verkehr")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
  end

  # typo: d_a_s Staats...
  test 'Staatsministeriums für Gesundheit und Pflege' do
    paper = paper_with_answerer('das Staatsministeriums für Gesundheit und Pflege')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  # typo: S_aats...
  test 'Saatsministeriums des Innern, für Bau und Verkehr' do
    paper = paper_with_answerer('des Saatsministeriums des Innern, für Bau und Verkehr')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
  end

  test 'Staatsministeriums Staatsministerium für Gesundheit und Pflege' do
    paper = paper_with_answerer("des Staatsministeriums Staatsministerium für Gesundheit\n und Pflege")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  test 'Bayerischen Staatskanzlei' do
    paper = paper_with_answerer('der Bayerischen Staatskanzlei')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Staatsministerin für Gesundheit und Pflege' do
    paper = paper_with_answerer('der Staatsministerin für Gesundheit und Pflege')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  test 'Staatsministerin für Gesundheit und Pflege with newline' do
    paper = paper_with_answerer("Staatsministerin für Gesundheit und Pflege\n")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
  end

  test 'Staatsministerin für Europaangelegenheiten newline' do
    paper = paper_with_answerer("der Staatsministerin für Europaangelegenheiten und regionale\n Beziehungen in der Staatskanzlei")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Europaangelegenheiten und regionale Beziehungen in der Staatskanzlei', answerers[:ministries].first
  end

  test 'Staatsminister (missing s)' do
    paper = paper_with_answerer('des Staatsminister für Ernährung, Landwirtschaft und Forsten')
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Ernährung, Landwirtschaft und Forsten', answerers[:ministries].first
  end

  test 'Leiterin Bayerische Staatskanzlei' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei\nStaatsministerin für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'die Leiterin der Bayerischen Staatskanzlei und Staatsministerin' do
    paper = paper_with_answerer <<-EOS
      der Leiterin der Staatskanzlei und Staatsministerin für
      Bundesangelegenheiten und Sonderaufgaben
    EOS
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'die Leiterin der Bayerischen Staatskanzlei' do
    paper = paper_with_answerer("die Leiterin der Bayerischen Staatskanzlei\nStaatsministerin für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiters Bayerische Staatskanzlei und' do
    paper = paper_with_answerer("des Leiters der Bayerischen Staatskanzlei und\nStaatsministers für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiters Bayerische Staatskanzlei comma' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei,\nStaatsministerin für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiters Bayerische Staatskanzlei space' do
    paper = paper_with_answerer("des Leiters der Bayerischen Staatskanzlei \nStaatsminister für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiterin Bayerische Staatskanzlei Staatsministerin' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei Staatsministerin\n für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  test 'Leiterin Bayerische Staatskanzlei comma Staatsministerin' do
    paper = paper_with_answerer("der Leiterin der Bayerischen Staatskanzlei, Staatsministerin\n für Bundesangelegenheiten und Sonderaufgaben")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Bayerische Staatskanzlei', answerers[:ministries].first
  end

  # space after Antwort and before newline, newline in name
  test 'Staatsministeriums für Wirtschaft und Medien, Energie und Technologie' do
    paper = paper_with_answerer("Antwort \ndes Staatsministeriums für Wirtschaft und Medien, \nEnergie und Technologie\n vom", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium für Wirtschaft und Medien, Energie und Technologie', answerers[:ministries].first
  end

  test 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat no vom' do
    paper = paper_with_answerer("Antwort \ndes Staatsministeriums der Finanzen, für Landesentwicklung\n und Heimat\n09.05.2016", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat', answerers[:ministries].first
  end

  # two
  test 'two ministries, in Abstimmung' do
    paper = paper_with_answerer("Antwort des Staatsministeriums für Ernährung, Landwirtschaft und Forsten vom 19.12.2016\n" +
      "In Abstimmung mit dem Staatsministerium für Umwelt und Verbraucherschutz wird die o. g. Schriftliche Anfrage wie folgt beantwortet")
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 2, answerers[:ministries].size
    assert_equal 'Staatsministerium für Ernährung, Landwirtschaft und Forsten', answerers[:ministries].first
    assert_equal 'Staatsministerium für Umwelt und Verbraucherschutz', answerers[:ministries].second
  end

  test 'two ministries, im Einvernehmen, short' do
    paper = paper_with_answerer("Antwort des Staatsministeriums für Gesundheit und Pflege vom 23.12.2016\n\n" +
     "Die Schriftliche Anfrage wird im Einvernehmen mit dem Staatsministerium des Innern, für Bau und Verkehr wie folgt beantwortet", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 2, answerers[:ministries].size
    assert_equal 'Staatsministerium für Gesundheit und Pflege', answerers[:ministries].first
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].second
  end

  test 'two ministries, im Einvernehmen, long' do
    paper = paper_with_answerer("Antwort des Staatsministeriums der Finanzen, für Landesentwicklung und Heimat vom 03.02.2017\n" +
      "Die Schriftliche Anfrage \n"+
      "der Frau Abgeordneten Ruth Müller SPD vom 18. Januar 2017 betreffend „...“ \n" +
      "wird im Einvernehmen mit dem Staatsministerium der Justiz wie folgt beantwortet", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 2, answerers[:ministries].size
    assert_equal 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat', answerers[:ministries].first
    assert_equal 'Staatsministerium der Justiz', answerers[:ministries].second
  end

  test 'three ministries, in Abstimmung' do
    paper = paper_with_answerer("Antwort des Staatsministeriums des Innern, für Bau und Verkehr vom 15.02.2016\n" +
      "Die Schriftliche Anfrage wird in Abstimmung mit dem Staatsministerium der Finanzen, für Landesentwicklung und Heimat sowie dem Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst wie folgt beantwortet:", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 3, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
    assert_equal 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat', answerers[:ministries].second
    assert_equal 'Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst', answerers[:ministries].third
  end

  test 'eigth ministries, im Einvernehmen' do
    t = <<-EOS
      Antwort
      des Staatsministeriums der Finanzen, für Landesentwicklung
      und Heimat vom 18.07.2017

      Die Schriftliche Anfrage wird auf der Grundlage einer Abfrage
      und im Einvernehmen mit dem Staatsministerium für
      Umwelt und Verbraucherschutz (StMUV), dem Staatsministerium
      für Bildung und Kultus, Wissenschaft und Kunst
      (StMBW), dem Staatsministerium für Arbeit und Soziales,
      Familie und Integration (StMAS), dem Staatsministerium für
      Gesundheit und Pflege (StMGP), dem Staatsministerium
      des Innern, für Bau und Verkehr (StMI), dem Staatsministerium
      für Wirtschaft und Medien, Energie und Technologie
      (StMWi) und dem Staatsministerium für Ernährung, Landwirtschaft
      und Forsten (StMELF) wie folgt beantwortet
    EOS

    paper = paper_with_answerer(t, wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 8, answerers[:ministries].size
    assert_equal 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat', answerers[:ministries][0]
    assert_equal 'Staatsministerium für Umwelt und Verbraucherschutz (StMUV)', answerers[:ministries][1]
    assert_equal 'Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst (StMBW)', answerers[:ministries][2]
    assert_equal 'Staatsministerium für Arbeit und Soziales, Familie und Integration (StMAS)', answerers[:ministries][3]
    assert_equal 'Staatsministerium für Gesundheit und Pflege (StMGP)', answerers[:ministries][4]
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr (StMI)', answerers[:ministries][5]
    assert_equal 'Staatsministerium für Wirtschaft und Medien, Energie und Technologie (StMWi)', answerers[:ministries][6]
    assert_equal 'Staatsministerium für Ernährung, Landwirtschaft und Forsten (StMELF)', answerers[:ministries][7]
  end

  test 'one ministry, in Abstimmung' do
    paper = paper_with_answerer("Antwort des Staatsministeriums des Innern, für Bau und Verkehr vom 19.10.2015\n" +
      "Die Schriftliche Anfrage wird in Abstimmung mit allen Ressorts wie folgt beantwortet: ", wrap: false)
    answerers = BayernPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Staatsministerium des Innern, für Bau und Verkehr', answerers[:ministries].first
  end
end