require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  setup do
    ENV['NOMENKLATURA_HOST'] = 'localhost'
    ENV['NOMENKLATURA_APIKEY'] = 'dummy'
  end

  test 'nk_dataset: throws exception when in multiple bodies' do
    p = people(:multi_body_person)
    assert_equal 2, p.papers.size

    assert_raises(Exception) { p.nomenklatura_dataset }
  end

  test 'nk_sync: person with same name, do nothing' do
    p = people(:normal_person)
    assert_equal 1, p.papers.size

    resp = Nomenklatura::Entity.new(nil, 'name' => 'Normal Person', 'invalid' => false)
    Nomenklatura::Dataset.stub_any_instance(:entity_by_name, resp) do
      p.nomenklatura_sync!
    end

    assert_equal 1, p.papers.reload.size
    assert_equal 'Normal Person', p.name
  end

  test 'nk_sync: person with invalid name, delete' do
    p = people(:invalid_person)
    assert_equal 1, p.papers.size

    resp = Nomenklatura::Entity.new(nil, 'name' => 'Invalid Person', 'invalid' => true)
    Nomenklatura::Dataset.stub_any_instance(:entity_by_name, resp) do
      p.nomenklatura_sync!
    end

    assert_equal 0, p.papers.reload.size
    assert p.destroyed?
  end

  test 'nk_sync: person with name is alias of new person, change name' do
    p = people(:typo_person)
    assert_equal 1, p.papers.size

    canonical = { 'name' => 'Typo in Name', 'invalid' => false }
    resp = Nomenklatura::Entity.new(nil, 'name' => 'Typo in Namme', 'invalid' => false, 'canonical' => canonical)
    Nomenklatura::Dataset.stub_any_instance(:entity_by_name, resp) do
      p.nomenklatura_sync!
    end

    assert_equal 'Typo in Name', p.name
    assert_equal 1, p.papers.reload.size
    assert p.persisted?
  end

  test 'nk_sync: person with name is alias of existing person, rewrite papers, delete' do
    smnp = people(:shortened_middle_name_person)
    mnp = people(:middle_name_person)
    assert_equal 1, smnp.papers.size
    assert_equal 0, mnp.papers.size

    canonical = { 'name' => 'Test Middle Name', 'invalid' => false }
    resp = Nomenklatura::Entity.new(nil, 'name' => 'Test M. Name', 'invalid' => false, 'canonical' => canonical)
    Nomenklatura::Dataset.stub_any_instance(:entity_by_name, resp) do
      smnp.nomenklatura_sync!
    end

    assert_equal 0, smnp.papers.reload.size
    assert smnp.destroyed?
    assert_equal 1, mnp.papers.reload.size
    assert mnp.persisted?
  end
end
