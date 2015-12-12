require 'test_helper'

class OrganizationTest < ActiveSupport::TestCase
  test 'it uses the right nomenklatura dataset name' do
    assert_equal 'ka-parties', organizations(:one).nomenklatura_dataset
  end
end
