class PaperRedirect < ApplicationRecord
  belongs_to :body
  belongs_to :paper

  validates :body, presence: true
  validates :legislative_term, presence: true
  validates :reference, presence: true, uniqueness: { scope: [:body_id, :legislative_term] }
end
