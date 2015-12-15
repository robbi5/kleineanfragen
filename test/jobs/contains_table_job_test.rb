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

  test 'some more numbers like in BE 17/14442' do
    text = "U1 96,4 97,1 96,3 98,3 98,3 97,6 96,1 96,0 96,0 \n\n" +
           "U2 96,1 95,1 97,6 97,6 98,1 97,4 97,3 96,8 97,1 \n\n" +
           'U3 98,8 98,2 98,3 99,0 99,4 99,2 99,0 98,8 98,8'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end

  test 'month table in BE 17/14442' do
    text = "Juni 2014 21.844  \n\n" +
           "Juli 2014 32.982  \n\n" +
           "Juli 2014 -20.000 -1.113 -439 -220 -7.722 -7.276 -6.109  \n\n" +
           'Summe 233.217'
    probability = ContainsTableJob.recognize(text)
    assert_operator probability, :>=, 1
  end
end
