require 'test_helper'

class SaarlandPDFExtractorDoctypeTest < ActiveSupport::TestCase
  test 'written interpellation' do
    paper = Struct.new(:contents).new(
      "\nA N T W O R T \n \n\nzu der  \n \n\nAnfrage der Abgeordneten" +
      " Dr. Simone Peter (B90/Grüne) \n \n \nbetr.:")

    doctype = SaarlandPDFExtractor.new(paper).extract_doctype
    assert_equal Paper::DOCTYPE_WRITTEN_INTERPELLATION, doctype
  end

  test 'major interpellation' do
    paper = Struct.new(:contents).new(
      "\nSCHRIFTLICHE ANTWORT \n \n\nder Regierung des Saarlandes \n \n\n" +
      "zu der  \n \n\nGroßen Anfrage der B90/Grüne-Landtagsfraktion ")

    doctype = SaarlandPDFExtractor.new(paper).extract_doctype
    assert_equal Paper::DOCTYPE_MAJOR_INTERPELLATION, doctype
  end
end