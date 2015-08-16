class Person < ActiveRecord::Base
  include NkSyncable

  has_and_belongs_to_many :organizations

  has_many :paper_originators, as: :originator
  has_many :papers, -> { answers }, through: :paper_originators

  validates :name, uniqueness: true

  def bodies
    Body.find papers.pluck(:body_id).uniq
  end
end
