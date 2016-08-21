class LegislativeTerm < ApplicationRecord
  belongs_to :body

  has_many :papers, -> (lt) { where(legislative_term: lt.term) }, through: :body
end
