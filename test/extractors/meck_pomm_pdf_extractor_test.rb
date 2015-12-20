require 'test_helper'

class MeckPommPDFExtractorTest < ActiveSupport::TestCase
  test 'normal ministry' do
    paper = Struct.new(:contents).new(
      "Der Minister für Bildung, Wissenschaft und Kultur hat namens der Landesregierung die Kleine Anfrage mit\n\nSchreiben vom 16. November 2015 beantwortet."
    )

    answerers = MeckPommPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Bildung, Wissenschaft und Kultur', answerers[:ministries].first
  end

  test 'normal ministry 6/1332' do
    paper = Struct.new(:contents).new(
      "Die Ministerin für Arbeit, Gleichstellung und Soziales hat namens der Landesregierung die Kleine Anfrage mit\n\nSchreiben vom 27. November 2012 beantwortet."
    )

    answerers = MeckPommPDFExtractor.new(paper).extract_answerers

    assert_equal 1, answerers[:ministries].size
    assert_equal 'Ministerium für Arbeit, Gleichstellung und Soziales', answerers[:ministries].first
  end

  test 'extract party 6/4151' do
    paper = Struct.new(:contents).new(
      "KLEINE ANFRAGE\n\nder Abgeordneten Barbara Borchardt und Torsten Koplin, Fraktion DIE LINKE\n"
    )

    origniators_party = MeckPommPDFExtractor.new(paper).extract_originators

    assert_equal 1, origniators_party[:parties].size
    assert_equal 'DIE LINKE', origniators_party[:parties].first
  end

  test 'extract party, with garbage' do
    paper = Struct.new(:contents).new(
      "KLEINE ANFRAGE\n\n" +
      "der Abgeordneten Barbara Borchardt und Torsten Koplin, Fraktion DIE LINKE asasdkfj\n" +
      'asdfasdf asdf a asdf HALLO'
    )

    origniators_party = MeckPommPDFExtractor.new(paper).extract_originators

    assert_equal 1, origniators_party[:parties].size
    assert_equal 'DIE LINKE', origniators_party[:parties].first
  end

  test 'regression 6/4717' do
    paper = Struct.new(:contents).new(
      "[...]KLEINE ANFRAGE\nder Abgeordneten Jacqueline Bernhardt, Fraktion DIE LINKE\n" +
        "Unbegleitete minderjährige Ausländer\nund [...]\n" +
        "Die Landesregierung verweist bezüglich der Anzahl der aufgenommenen unbegleiteten\n" +
        "minderjährigen Ausländer in den Jahren 2012, 2013 und 2014 auf die Landtagsdrucksache\n" +
        "6/3568 (Kleine Anfrage der Abgeordneten Jacqueline Bernhardt und Dr. Hikmat Al-\n" +
        "Sabty, Fraktion DIE LINKE zur Situation der unbegleiteten minderjährigen Flüchtlinge vom\n" +
        "13. Januar 2015).\n"
    )

    origniators_party = MeckPommPDFExtractor.new(paper).extract_originators

    assert_equal 1, origniators_party[:parties].size
    assert_equal 'DIE LINKE', origniators_party[:parties].first
  end
end


