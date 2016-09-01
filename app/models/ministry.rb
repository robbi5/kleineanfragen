class Ministry < ApplicationRecord
  extend FriendlyId
  acts_as_paranoid
  include NkSyncable

  belongs_to :body

  friendly_id :name, use: :scoped, scope: :body

  has_many :paper_answerers, as: :answerer, dependent: :destroy
  has_many :papers, -> { answers }, through: :paper_answerers

  validates :name, uniqueness: { scope: [:body_id] }
end
