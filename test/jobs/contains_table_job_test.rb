require 'test_helper'

class ContainsTableJobTest < ActiveSupport::TestCase
  test 'nachstehende Tabelle' do
    text = 'die nachstehende Tabelle enthält'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'Tabelle 2 zeigt' do
    text = 'Tabelle 2 zeigt'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'Daten (Tabelle 3)' do
    text = 'Daten (Tabelle 3)'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'some numbers' do
    text = "30\n50\n20\n15\n23\n42\n\n"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'some more numbers like in BE 17/14442' do
    text = "\nU1 96,4 97,1 96,3 98,3 98,3 97,6 96,1 96,0 96,0 \n\n" +
           "U2 96,1 95,1 97,6 97,6 98,1 97,4 97,3 96,8 97,1 \n\n" +
           "U3 98,8 98,2 98,3 99,0 99,4 99,2 99,0 98,8 98,8\n"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'simple faked table' do
    text = "\nAAA -11.234\nBBB 123\nCCC 1,23\n"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'month table from BE 17/14442' do
    text = "Juni 2014 21.844  \n\n" +
           "Juli 2014 32.982  \n\n" +
           "Juli 2014 -20.000 -1.113 -439 -220 -7.722 -7.276 -6.109  \n\n" +
           'Summe 233.217'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'table from TH 6/1379' do
    text = "\nStellenanteil Anzahl der Verträge\n" +
           "unter 25 Prozent 10\n" +
           "25 bis 50 Prozent 17\n" +
           "50 bis 75 Prozent 25\n" +
           "75 bis 100 Prozent 31\n"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'table from ST 6/4864' do
    text = "\n\n" +
           "Zens Schweinemast 2.496 3.768\n" +
           "Zeppernick Hähnchenmastanlage 75.000\n" +
           "Zeppernick Hähnchenmastanlage 100.000\n" +
           "Moritz Rinderanlage 520\n" +
           "Zernitz Milchviehanlage 650\n" +
           "Hohenlepte Elterntierhaltung 19.500\n" +
           "Deetz Milchviehanlage 360 60\n\n"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'no table: some text with a date' do
    text = "Antwort des Niedersächsischen Ministeriums für Inneres und Sport namens der Landesregierung\n" +
           " vom 09.12.2015,  \n\n" +
           'gezeichnet '
    probability = ContainsTableJob.recognize(text)
    assert_equal 0, probability
  end

  test 'no table: some date on a new line' do
    text = "\n\n  \n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n \n\n5.8.2015 \n\n \n\n\n\n 2 \n\n"
    probability = ContainsTableJob.recognize(text)
    assert_equal 0, probability
  end

  test 'no table: two date lines' do
    text = "Schriftliche Anfrage\ndes Abgeordneten ...\nvom 14.09.2015\n" +
           "\n\n\nAntwort\ndes Staatsministeriums für ...\nvom 22.10.2015\n"
    probability = ContainsTableJob.recognize(text)
    assert_equal 0, probability
  end
end
