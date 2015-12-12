class Organization < ActiveRecord::Base
  include NkSyncable

  has_and_belongs_to_many :members, class_name: 'Person'

  has_many :paper_originators, as: :originator
  has_many :papers, -> { answers }, through: :paper_originators

  validates :name, uniqueness: true

  def nomenklatura_dataset
    'ka-parties'
  end
end
