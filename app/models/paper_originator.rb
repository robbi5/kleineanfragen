class PaperOriginator < ActiveRecord::Base
  belongs_to :paper
  belongs_to :originator, polymorphic: true

  validates_uniqueness_of :originator_id, scope: [:paper_id, :originator_type]
end
