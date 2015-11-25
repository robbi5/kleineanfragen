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

  # Trailing comma, party
  test 'two people, trailing comma and party' do
    pair = NamePartyExtractor.new('Andrea Schröder-Ehlers (SPD), Dr. Thela Wernstedt, (SPD)').extract

    assert_equal 2, pair[:people].size
    assert_equal 'Andrea Schröder-Ehlers', pair[:people].first
    assert_equal 'Dr. Thela Wernstedt', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
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

  test 'rnp: three people, one with location in brackets' do
    pair = NamePartyExtractor.new('Hofmann, Heike, SPD; Müller(Schwalmstadt), Regine, SPD; Rudolph, Günter, SPD', :rnp).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Heike Hofmann', pair[:people].first
    assert_equal 'Regine Müller', pair[:people].second
    assert_equal 'Günter Rudolph', pair[:people].third
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

  test 'rnp: two people, one with two names, and others, spaced party' do
    pair = NamePartyExtractor.new('Lamla, Lukas Markus; Düngel, Daniel u.a. PIRATEN', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Lukas Markus Lamla', pair[:people].first
    assert_equal 'Daniel Düngel', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'PIRATEN', pair[:parties].first
  end

  test 'rnp: two people, one with two names, and others, spaced party 2' do
    pair = NamePartyExtractor.new('Schmitz, Ingola Stefanie; Abruszat, Kai u.a. FDP', :rnp).extract

    assert_equal 2, pair[:people].size
    assert_equal 'Ingola Stefanie Schmitz', pair[:people].first
    assert_equal 'Kai Abruszat', pair[:people].second
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP', pair[:parties].first
  end

  test 'rnp: four people, and others, spaced parties' do
    pair = NamePartyExtractor.new('Römer, Norbert; Herter, Marc u.a. SPD; Priggen, Reiner; Beer, Sigrid u.a. GRÜNE', :rnp).extract

    assert_equal 4, pair[:people].size
    assert_equal 'Norbert Römer', pair[:people].first
    assert_equal 'Marc Herter', pair[:people].second
    assert_equal 'Reiner Priggen', pair[:people].third
    assert_equal 'Sigrid Beer', pair[:people].fourth
    assert_equal 2, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
    assert_equal 'GRÜNE', pair[:parties].second
  end

  test 'rnp: four people, and others, spaced parties, cleaned' do
    pair = NamePartyExtractor.new('Römer, Norbert; Herter, Marc SPD; Priggen, Reiner; Beer, Sigrid u.a. GRÜNE', :rnp).extract

    assert_equal 4, pair[:people].size
    assert_equal 'Norbert Römer', pair[:people].first
    assert_equal 'Marc Herter', pair[:people].second
    assert_equal 'Reiner Priggen', pair[:people].third
    assert_equal 'Sigrid Beer', pair[:people].fourth
    assert_equal 2, pair[:parties].size
    assert_equal 'SPD', pair[:parties].first
    assert_equal 'GRÜNE', pair[:parties].second
  end

  test 'rnp: three people, with prefixed title, spaced parties' do
    pair = NamePartyExtractor.new('Dr. Nachname, Vorname; Prof. Dr. Test, Vorname ABC; Brockes, Dietmar FDP', :rnp).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Dr. Vorname Nachname', pair[:people].first
    assert_equal 'Prof. Dr. Vorname Test', pair[:people].second
    assert_equal 'Dietmar Brockes', pair[:people].third
    assert_equal 2, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
    assert_equal 'FDP', pair[:parties].second
  end

  test 'rnp: three people, and others, one fraktionslos' do
    pair = NamePartyExtractor.new('Jung, Volker; Krückel, Bernd u.a. CDU; Stein, Robert fraktionslos', :rnp).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Volker Jung', pair[:people].first
    assert_equal 'Bernd Krückel', pair[:people].second
    assert_equal 'Robert Stein', pair[:people].third
    assert_equal 2, pair[:parties].size
    assert_equal 'CDU', pair[:parties].first
    assert_equal 'fraktionslos', pair[:parties].second
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

  test 'npc: one person with title and double name, one party' do
    pair = NamePartyExtractor.new('Dr. Hans-Ulrich Rülke FDP/DVP', :npc).extract

    assert_equal 1, pair[:people].size
    assert_equal 'Dr. Hans-Ulrich Rülke', pair[:people].first
    assert_equal 1, pair[:parties].size
    assert_equal 'FDP/DVP', pair[:parties].first
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

  test 'npc: three people seperated by comma and und, one party, newlines' do
    pair = NamePartyExtractor.new("Vor Nachname, Anderer Name\n\nund Anderer Nachname ABC", :npc).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Vor Nachname', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 'Anderer Nachname', pair[:people].third
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end

  test 'npc: people seperated by comma and und, one party but surname only 3 letters' do
    pair = NamePartyExtractor.new("Vorname Nac, Anderer Name und Andre Name ABC", :npc).extract

    assert_equal 3, pair[:people].size
    assert_equal 'Vorname Nac', pair[:people].first
    assert_equal 'Anderer Name', pair[:people].second
    assert_equal 'Andre Name', pair[:people].third
    assert_equal 1, pair[:parties].size
    assert_equal 'ABC', pair[:parties].first
  end

  test 'looks_like_party? FDP' do
    assert NamePartyExtractor.looks_like_party? 'FDP'
  end

  test 'looks_like_party? AfD' do
    assert NamePartyExtractor.looks_like_party? 'AfD'
  end

  test 'looks_like_party? BÜNDNIS 90/DIE GRÜNEN' do
    assert NamePartyExtractor.looks_like_party? 'BÜNDNIS 90/DIE GRÜNEN'
  end
end