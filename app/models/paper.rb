class Paper < ActiveRecord::Base
  extend FriendlyId
  friendly_id :reference_and_title, use: :scoped, scope: [:body, :legislative_term]

  belongs_to :body
  has_many :paper_originators
  has_many :originator_people, :through => :paper_originators, :source => :originator, :source_type => 'Person'
  has_many :originator_organizations, :through => :paper_originators, :source => :originator, :source_type => 'Organization'

  def originators
    paper_originators.collect(&:originator)
  end

  validates :reference, uniqueness: { scope: [:body_id, :legislative_term] }

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def reference_and_title
    [
      [:reference, :title]
    ]
  end

  def normalize_friendly_id(value)
    value.to_s.gsub('&', 'und').parameterize.truncate(120, separator: '-', omission: '')
  end

  def full_reference
    legislative_term.to_s + '/' + reference.to_s
  end
end
