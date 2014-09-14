class Paper < ActiveRecord::Base
  belongs_to :body
  has_many :paper_originators
  has_many :originator_people, :through => :paper_originators, :source => :originator, :source_type => 'Person'
  has_many :originator_organizations, :through => :paper_originators, :source => :originator, :source_type => 'Organization'

  def originators
    paper_originators.collect(&:originator)
  end

  validates :reference, uniqueness: { scope: [:body_id, :legislative_term] }
end
