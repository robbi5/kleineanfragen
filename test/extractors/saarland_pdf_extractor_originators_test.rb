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
    paper = Struct.new(:contents).new("Anfrage der Abgeordneten Astrid Schramm (DIE LINKE.)")

    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Astrid Schramm', originators[:people].first
    assert_equal 'DIE LINKE.', originators[:parties].first
  end

  test 'one person, multiline' do
    paper = Struct.new(:contents).new("Anfrage der Abgeordneten Astrid\nSchramm (DIE LINKE.)")

    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Astrid Schramm', originators[:people].first
    assert_equal 'DIE LINKE.', originators[:parties].first
  end

  test 'one person, whole' do
    paper = Struct.new(:contents).new(File.read(Rails.root.join('test/fixtures/saarland_paper.txt')))
    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 1, originators[:people].size
    assert_equal 'Michael Neyses', originators[:people].first
    assert_equal 'B90/Grüne', originators[:parties].first
  end

  test 'two people, connected by und' do
    paper = Struct.new(:contents).new("Anfrage der Abgeordneten\n\nJasmin Maurer und Michael Neyses (PIRATEN)")

    originators = SaarlandPDFExtractor.new(paper).extract_originators

    assert_equal 2, originators[:people].size
    assert_equal 'Jasmin Maurer', originators[:people].first
    assert_equal 'Michael Neyses', originators[:people].second
    assert_equal 'PIRATEN', originators[:parties].first
  end
end