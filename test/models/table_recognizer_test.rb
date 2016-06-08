require 'test_helper'

class TableRecognizerTest < ActiveSupport::TestCase

  def assert_table(text)
    result = TableRecognizer.new(text).recognize
    assert_operator result[:probability], :>=, 1
  end

  def assert_no_table(text)
    result = TableRecognizer.new(text, debug: true).recognize
    assert_equal 0, result[:probability], "Groups: #{result[:groups]}\nMatches: #{result[:matches]}"
  end

  test 'nachstehende Tabelle' do
    assert_table 'die nachstehende Tabelle enthält'
  end

  test 'Tabelle 2 zeigt' do
    assert_table 'Tabelle 2 zeigt'
  end

  test 'skip, Tabelle 2 zeigt' do
    text = 'Tabelle 2 zeigt'
    result = TableRecognizer.new(text, skip: [:table_shows]).recognize
    assert_equal 0, result[:probability], "Groups: #{result[:groups]}\nMatches: #{result[:matches]}"
  end

  test 'Daten (Tabelle 3)' do
    assert_table 'Daten (Tabelle 3)'
  end

  test 'some numbers' do
    assert_table "30\n50\n20\n15\n23\n42\n\n"
  end

  test 'some more numbers like in BE 17/14442' do
    assert_table "\nU1 96,4 97,1 96,3 98,3 98,3 97,6 96,1 96,0 96,0 \n\n" +
                 "U2 96,1 95,1 97,6 97,6 98,1 97,4 97,3 96,8 97,1 \n\n" +
                 "U3 98,8 98,2 98,3 99,0 99,4 99,2 99,0 98,8 98,8\n"
  end

  test 'simple faked table' do
    assert_table "\nAAA -11.234\nBBB 123\nCCC 1,23\n"
  end

  test 'month table from BE 17/14442' do
    assert_table "Juni 2014 21.844  \n\n" +
                 "Juli 2014 32.982  \n\n" +
                 "Juli 2014 -20.000 -1.113 -439 -220 -7.722 -7.276 -6.109  \n\n" +
                 'Summe 233.217'
  end

  test 'table from TH 6/1379' do
    assert_table "\nStellenanteil Anzahl der Verträge\n" +
                 "unter 25 Prozent 10\n" +
                 "25 bis 50 Prozent 17\n" +
                 "50 bis 75 Prozent 25\n" +
                 "75 bis 100 Prozent 31\n"
  end

  test 'table from ST 6/4864' do
    assert_table "\n\n" +
                 "Zens Schweinemast 2.496 3.768\n" +
                 "Zeppernick Hähnchenmastanlage 75.000\n" +
                 "Zeppernick Hähnchenmastanlage 100.000\n" +
                 "Moritz Rinderanlage 520\n" +
                 "Zernitz Milchviehanlage 650\n" +
                 "Hohenlepte Elterntierhaltung 19.500\n" +
                 "Deetz Milchviehanlage 360 60\n\n"
  end

  test 'no table: some text with a date' do
    assert_no_table "Antwort des Niedersächsischen Ministeriums für Inneres und Sport namens der Landesregierung\n" +
                    " vom 09.12.2015,  \n\n" +
                    'gezeichnet '
  end

  test 'no table: some date on a new line' do
    assert_no_table "\n\n  \n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n5.8.2015 \n\n \n\n\n\n 2 \n\n"
  end

  test 'no table: two date lines' do
    assert_no_table "Schriftliche Anfrage\ndes Abgeordneten ...\nvom 14.09.2015\n" +
                    "\n\n\nAntwort\ndes Staatsministeriums für ...\nvom 22.10.2015\n"
  end

  # test 'no table: from file' do
  #   text = File.read(Rails.root.join('test/fixtures/contents.txt'))
  #   probability = TableRecognizer.new(text, debug: true).recognize
  #   assert_equal 0, probability
  # end
end
