class PaperOriginator < ActiveRecord::Base
  belongs_to :paper
  belongs_to :originator, polymorphic: true

  validates :originator_id,
    uniqueness: { scope: [:paper_id, :originator_type] },
    unless: Proc.new { |o| o.paper_id.blank? || o.originator_type.blank? }
end
