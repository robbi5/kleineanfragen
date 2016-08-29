class LegislativeTerm < ApplicationRecord
  belongs_to :body

  validates :term, uniqueness: { scope: [:body_id] }

  has_many :papers, -> (lt) { where(legislative_term: lt.term) }, through: :body

  def to_param
    term
  end
end
