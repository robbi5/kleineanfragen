require 'test_helper'

class PDFExtractorTest < ActiveSupport::TestCase

  test 'one ministry' do
    ministries = PDFExtractor.split_ministries("Ministerium für XLändlichen Raum")

    assert_equal 1, ministries.size
    assert_equal 'Ministerium für XLändlichen Raum', ministries.first
  end

  test 'two ministries, sowie' do
    ministries = PDFExtractor.split_ministries("Ministerium für Ländlichen Raum, sowie dem Ministerium für Finanzen und Wirtschaft")

    assert_equal 2, ministries.size
    assert_equal 'Ministerium für Ländlichen Raum', ministries.first
    assert_equal 'Ministerium für Finanzen und Wirtschaft', ministries.second
  end

  test 'two staatsministries, sowie' do
    ministries = PDFExtractor.split_ministries("Staatsministerium der Finanzen, für Landesentwicklung und Heimat sowie dem Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst")

    assert_equal 2, ministries.size
    assert_equal 'Staatsministerium der Finanzen, für Landesentwicklung und Heimat', ministries.first
    assert_equal 'Staatsministerium für Bildung und Kultus, Wissenschaft und Kunst', ministries.second
  end

  test 'three ministries, sowie' do
    ministries = PDFExtractor.split_ministries("Ministerium für Ländlichen Raum, " +
      "sowie dem Ministerium für Finanzen und Wirtschaft "+
      "und dem Ministerium für Wissenschaft, Forschung und Kunst")

    assert_equal 3, ministries.size
    assert_equal 'Ministerium für Ländlichen Raum', ministries.first
    assert_equal 'Ministerium für Finanzen und Wirtschaft', ministries.second
    assert_equal 'Ministerium für Wissenschaft, Forschung und Kunst', ministries.third
  end
end