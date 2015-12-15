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
    text = "30\n50\n20\n15\n23\n42"
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end
end
