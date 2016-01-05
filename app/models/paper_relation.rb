class PaperRelation < ActiveRecord::Base
  REASON_REFERENCE_IN_TEXT = 'reference_in_text'

  belongs_to :paper
  belongs_to :other_paper
end
