require 'test_helper'

class NamePartyExtractorTest < ActiveSupport::TestCase
  # Danny Freymark (CDU)
  test 'one person, one party, single line' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU)').extract

    assert_equal 1, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  # Danny Freymark (CDU), Alexander J. Herrmann (CDU)
  test 'two people, same party, single line' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU), Alexander J. Herrmann (CDU)').extract

    assert_equal 2, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 'Alexander J. Herrmann', pair[:people].last
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  # Danny Freymark (CDU) und Alexander J. Herrmann (CDU)
  test 'two people, same party, seperated by und' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU) und Alexander J. Herrmann (CDU)').extract

    assert_equal 2, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 'Alexander J. Herrmann', pair[:people].last
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  # Dora Heyenn (Fraktion DIE LINKE), Dr. Joachim Bischoff (Fraktion DIE LINKE), Wolfgang Joithe-von Krosigk (Fraktion DIE LINKE)
  test 'three people, same party, removes Fraktion' do
    names = 'Dora Heyenn (Fraktion DIE LINKE), Dr. Joachim Bischoff (Fraktion DIE LINKE), Wolfgang Joithe-von Krosigk (Fraktion DIE LINKE)'
    pair = NamePartyExtractor.new(names).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Dora Heyenn', pair[:people].first
    assert_equal 'Dr. Joachim Bischoff', pair[:people].second
    assert_equal 'Wolfgang Joithe-von Krosigk', pair[:people].last
    assert_equal 1, pair[:parties].size
    assert_equal 'DIE LINKE', pair[:parties].first
  end

  # Danny Freymark
  test 'one person, no party, single line' do
    pair = NamePartyExtractor.new('Danny Freymark').extract

    assert_equal 1, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 0, pair[:parties].size
  end

  # Trailing comma, space
  test 'one person, trailing comma and space' do
    pair = NamePartyExtractor.new('Danny Freymark (CDU), ').extract

    assert_equal 1, pair[:people].size
    assert_equal 'Danny Freymark', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
  end

  ###
  # Reversed Name Party Format
  ###

  test 'rnp: two people, two parties' do
    pair = NamePartyExtractor.new('Weiß, Marius, SPD; Schmitt, Norbert, SPD', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Marius Weiß', pair[:people].first
    assert_equal 'Norbert Schmitt', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
  end

  test 'rnp: two people, one party' do
    pair = NamePartyExtractor.new('Brockes, Dietmar; Ellerbrock, Holger, FDP', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Dietmar Brockes', pair[:people].first
    assert_equal 'Holger Ellerbrock', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: one person with title' do
    pair = NamePartyExtractor.new('Sommer, Daniela, Dr., SPD', :rnp).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Dr. Daniela Sommer', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
  end

  test 'rnp: one person with spaced title' do
    pair = NamePartyExtractor.new('Hahn, Jörg-Uwe, Dr. h.c., FDP', :rnp).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Dr. h.c. Jörg-Uwe Hahn', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: one person with spaced party' do
    pair = NamePartyExtractor.new('Test, Muster SPD', :rnp).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Muster Test', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
  end

  test 'rnp: two people, one spaced party' do
    pair = NamePartyExtractor.new('Brockes, Dietmar; Ellerbrock, Holger FDP', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Dietmar Brockes', pair[:people].first
    assert_equal 'Holger Ellerbrock', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: two people, one spaced party and others' do
    pair = NamePartyExtractor.new('Brockes, Dietmar; Ellerbrock, Holger u.a. FDP', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Dietmar Brockes', pair[:people].first
    assert_equal 'Holger Ellerbrock', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: one person with two names and spaced party' do
    pair = NamePartyExtractor.new('Schmitz, Ingola Stefanie FDP', :rnp).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Ingola Stefanie Schmitz', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: only party' do
    pair = NamePartyExtractor.new('FDP', :rnp).extract

    assert_equal 0, pair[:people].size
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: only fraktion party' do
    pair = NamePartyExtractor.new('Fraktion FDP', :rnp).extract

    assert_equal 0, pair[:people].size
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: remove der from fraktion party' do
    pair = NamePartyExtractor.new('Fraktion der FDP', :rnp).extract

    assert_equal 0, pair[:people].size
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  ###
  # Name Party Comma Format
  ###

  test 'npc: one person, simple party' do
    pair = NamePartyExtractor.new('Vor Nachname ABC', :npc).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end

  test 'npc: one person, mixed party' do
    pair = NamePartyExtractor.new('Vor Nachname AbC', :npc).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'AbC', pair[:parties].first
  end

  test 'npc: one person, spaced party' do
    pair = NamePartyExtractor.new('Klaus Bartl DIE LINKE', :npc).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Klaus Bartl', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'DIE LINKE', pair[:parties].first
  end

  test 'npc: one person, party with slash' do
    pair = NamePartyExtractor.new('Vor Nachname ABC/DEF', :npc).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC/DEF', pair[:parties].first
  end

  test 'npc: two people, same simple party' do
    pair = NamePartyExtractor.new('Vor Nachname ABC, Anderer Name ABC', :npc).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end

  test 'npc: two people, same mixed party' do
    pair = NamePartyExtractor.new('Vor Nachname AbC, Anderer Name AbC', :npc).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'AbC', pair[:parties].first
  end

  test 'npc: two people, same spaced party' do
    pair = NamePartyExtractor.new('Klaus Bartl DIE LINKE, Rico Gebhardt DIE LINKE', :npc).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Klaus Bartl', pair[:people].first
    assert_equal 'Rico Gebhardt', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'DIE LINKE', pair[:parties].first
  end

  test 'npc: two people, one party' do
    pair = NamePartyExtractor.new('Vor Nachname, Anderer Name ABC', :npc).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end

  test 'npc: two people seperated by und, one party' do
    pair = NamePartyExtractor.new('Vor Nachname und Anderer Name ABC', :npc).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end
end