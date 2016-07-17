class PaperRelation < ApplicationRecord
  REASON_REFERENCE_IN_TITLE = 'reference_in_title'
  REASON_REFERENCE_IN_TEXT = 'reference_in_text'

  belongs_to :paper
  belongs_to :other_paper, class_name: 'Paper'

  validates :paper, :other_paper, :reason, presence: true
  validates :other_paper, uniqueness: { scope: [:paper, :reason] }
  validate :does_not_link_itself

  private

  def does_not_link_itself
    if !paper.nil? && !other_paper.nil? && paper.id == other_paper.id
      errors.add(:other_paper, 'cannot be the same paper')
    end
  end
end
