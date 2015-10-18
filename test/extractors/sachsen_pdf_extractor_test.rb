require 'test_helper'

class SachsenPDFExtractorTest < ActiveSupport::TestCase
  # Extracted from real ocr results:
  # papers = Paper.find_by_sql(["SELECT p.* FROM papers p LEFT OUTER JOIN paper_answerers o ON (o.paper_id = p.id AND o.answerer_type = 'Ministry') WHERE p.body_id = ? AND o.id IS NULL AND p.contents IS NOT NULL ORDER BY id DESC LIMIT 100", Body.find_by_state("SN").id])
  # papers.map {|p| p.contents[0...60].gsub(/\p{Z}/, ' ').gsub(/\n/, ' ').gsub(/\s+/, ' ').strip }.uniq

  # rubocop:disable Style/ExtraSpacing
  TEST_PAIRS = {
    'STAATSM1N1STER1UM FÜR SOZIALES UND VERBRAUCHERSCHUTZ SÄ'      => 'Staatsministerium für Soziales und Verbraucherschutz',
    'STAATSMlNlSTERlUM FÜR SOZIALES UND VERBRAUCHERSCHUTZ SÄ'      => 'Staatsministerium für Soziales und Verbraucherschutz',
    'STAATSMlNlSTERlUM FÜR SOllALES UND VERBRAlJCl-lERSCl-lUTZ'    => 'Staatsministerium für Soziales und Verbraucherschutz',

    'STAATSMINISTERIUI\\4 FÜR UMWELT UND LANDWIRTSCHAFT SÄCHSISCH' => 'Staatsministerium für Umwelt und Landwirtschaft',
    'STAATSI/INISTERIUM FÜR UMWELT UND LANDWIRTSCHAFT SACHSISCHE'  => 'Staatsministerium für Umwelt und Landwirtschaft',
    'SÄCHSISCHES STAATSMINISTERIUM DER FINANZEN Postfach 100 948'  => 'Staatsministerium der Finanzen',
    'SACHSISCHES STAATSMINISTERIUM DER JUSTIZ Hosp¡talstr 7 | 010' => 'Staatsministerium der Justiz',
    'Sächsisches Staatsministerium für Wirtschaft, Arbeit und Ver' => 'Staatsministerium für Wirtschaft, Arbeit und Verkehr',

    # Kultus
    'SÄCHSISCHES STAATSMINISTERIUM FÜR KULTUS Postfach 10 09 10'   => 'Staatsministerium für Kultus',
    'SÄCHSISCHES STAATSMINISTERIUM FÜR KULTU S Poslfac'            => 'Staatsministerium für Kultus',
    'SÄCHSISCHES STMTSMINISTERIUM FÜR KULTU S PosIfach'            => 'Staatsministerium für Kultus',

    # Inneres
    'STAATSMINISTEWUM ÜES INNERN Freistaat SACHSEN DerStaatsmi'    => 'Staatsministerium des Innern',
    'STAATSM1N1STEDIUM DES INNERN Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'DES INNERN Freistaat e" » /"»i i r-T-^ Der Staatsminister'    => 'Staatsministerium des Innern',
    'STAATSM1N1STETOUM DES INNEBM Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'STAATSM11MISTER1UM DES INNERN Freistaat SACHSEN Der Staat'    => 'Staatsministerium des Innern',
    'STAATSM1NISTER1UM DES 1MNERIM Freistaat SACHSEN Der Staat'    => 'Staatsministerium des Innern',
    'STAATSM1N1STEKIUM DES INNERN Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'STAATSMINISTERIUM DBS 11WERN Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'STAATSM1NISTBK1UM DES 1NMERN Der Staatsminister SÄCHSISCHE'   => 'Staatsministerium des Innern',
    'STAATSMINISTBR1UM DES INNERN Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'STAATSM1NISTEDIUM DES INNERN Der Staatsminister SÄCHSISCHE'   => 'Staatsministerium des Innern',
    'STAATSM1N1STERIUM DES 1NNEKN Der Staatsminister SÄCHSISCHE'   => 'Staatsministerium des Innern',
    'STAATSM1NBTEWUM DES INNERN Freistaat SACHSEN Der Staatsmi'    => 'Staatsministerium des Innern',
    'STAATSM1N1STBRIUM DES INNERN Freistaat SACHSEN Der Staats'    => 'Staatsministerium des Innern',
    'STAATSM1N15TEK1UM DBS INNERN Freistaat SÄCtiSBN Der Staat'    => 'Staatsministerium des Innern',
    'STAATSM11M1STEKIUM DES INNERN Freistaat SACHSEN Der Staat'    => 'Staatsministerium des Innern',
    'STAATSMIN1STBR1UM DES INNERN Freistaat SAC\'S-iSFTMj .jrv^n^' => 'Staatsministerium des Innern',
    'STAATSMIN1STER1UM DES INIMECTi Freistaat SÄCHSE1N'            => 'Staatsministerium des Innern',

    'Anlage zu KA 6/2578 Seite 1 von 7 Im Monat August 2015 w'     => nil,
    '6-2137_Seite_01 6-2137_Seite_02 6-2137_Seite_03 6-2137_Se'    => nil
  }
  # rubocop:enable Style/ExtraSpacing

  def paper_with_contents(contents)
    Struct.new(:contents).new(contents)
  end

  TEST_PAIRS.each_with_index do |(key, value), index|
    define_method "test_sachsen_pair_#{index}" do
      paper = paper_with_contents(key)
      answerers = SachsenPDFExtractor.new(paper).extract_answerers
      assert_equal value, answerers[:ministries].try(:first), "Should match \"#{value}\" for \"#{key}\""
    end
  end
end
