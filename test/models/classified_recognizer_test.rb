require 'test_helper'

class ClassifiedRecognizerTest < ActiveSupport::TestCase

  def assert_classified(text)
    result = ClassifiedRecognizer.new(text).recognize
    assert_operator result[:probability], :>=, 1
  end

  def assert_not_classified(text)
    result = ClassifiedRecognizer.new(text, debug: true).recognize
    assert_equal 0, result[:probability], "Groups: #{result[:groups]}\nMatches: #{result[:matches]}"
  end

  test 'Antwort als Verschlusssache eingestuft' do
    assert_classified 'ist die Antwort als Verschlusssache eingestuft'
  end

  test 'Antworten als Verschlusssache eingestuft' do
    assert_classified 'sind die Antworten als Verschlusssache eingestuft'
  end

  test 'bt 18/13553' do
    assert_classified "Um gleichwohl dem Aufklärungs- und Informationsrecht der Abgeordneten des \n" +
      "Deutschen Bundestages nachzukommen, werden die Antworten auf die gestellten \n" +
      "Fragen der Geheimschutzstelle des Deutschen Bundestages zugeleitet. \n"
  end

  test 'bt 18/2446' do
    assert_classified "Die Antwort \nwird daher in der Geheimschutzstelle des Bundestages hinterlegt.*"
    assert_classified "* Das Auswärtige Amt hat die Antwort als „VS – Geheim“ eingestuft.\n\n" +
      "Die Antwort ist in der Geheimschutzstelle des Deutschen Bundestages hinterlegt und kann dort nach \n" +
      "Maßgabe der Geheimschutzordnung eingesehen werden.\n"
  end

  test 'sh 7/1921' do
    assert_classified "\n*Hinweis:  Eine Einsichtnahme des vertraulichen Teils o. g. Antwort ist für Mitglieder des Landtages in \n" +
      "\nder Landtagsverwaltung - Geheimschutzstelle - nach Terminabsprache möglich."
  end

  test 'sn 6/9125' do
    assert_classified " Aufgrund dieser Einstufung der ausgewiesenen Straßen\n" +
      "und der für die Entscheidung zugrunde liegenden Erkenntnisse wurde die Beantwortung\n" +
      " der Frage an die Geheimschutzstelle des Sächsischen Landtages mit der Bitte\n" +
      "übersandt, den Damen und Herren Abgeordneten die Einsichtnahme zu ermöglichen."
  end

  test 'not classified: sample text' do
    assert_not_classified "hello world. this is a false positive test."
  end

  # test 'not classified: from file' do
  #   text = File.read(Rails.root.join('test/fixtures/contents.txt'))
  #   result = ClassifiedRecognizer.new(text).recognize
  #   assert_equal 0, result[:probability]
  # end
end
