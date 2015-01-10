class Ministry < ActiveRecord::Base
  belongs_to :body

  has_many :paper_answerers, as: :answerer
  has_many :papers, through: :paper_answerers

  validates :name, uniqueness: { scope: [:body_id] }
end
