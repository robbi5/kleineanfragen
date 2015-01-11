class Ministry < ActiveRecord::Base
  extend FriendlyId

  belongs_to :body

  friendly_id :name, use: :scoped, scope: :body

  has_many :paper_answerers, as: :answerer
  has_many :papers, through: :paper_answerers

  validates :name, uniqueness: { scope: [:body_id] }
end
