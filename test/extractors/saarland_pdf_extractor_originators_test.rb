require 'test_helper'

class SaarlandPDFExtractorOriginatorsTest < ActiveSupport::TestCase

  test 'one person, single line' do
    paper = Struct.new(:contents).new("   Anfrage   des   Abgeordneten   Michael   Neyses  (PIRATEN)   \n")

    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Michael Neyses', originators[:people].first
    assert_equal 'PIRATEN', originators[:parties].first
  end

  test 'one person, single line 2' do
    paper = Struct.new(:contents).new("Anfrage der Abgeordneten Astrid Schramm (DIE LINKE.) \n")

    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Astrid Schramm', originators[:people].first
    assert_equal 'DIE LINKE.', originators[:parties].first
  end

end