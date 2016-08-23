class Person < ApplicationRecord
  extend FriendlyId
  include NkSyncable

  friendly_id :name, use: :slugged

  has_and_belongs_to_many :organizations

  has_many :paper_originators, as: :originator
  has_many :papers, -> { answers }, through: :paper_originators

  validates :name, uniqueness: true

  def bodies
    Body.find papers.pluck(:body_id).uniq
  end

  def latest_body
    Body.find papers.order(created_at: :desc).limit(1).pluck(:body_id).first
  end
end
