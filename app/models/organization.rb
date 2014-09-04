class Organization < ActiveRecord::Base
  has_and_belongs_to_many :members, class_name: "Person"

  has_many :paper_originators, as: :originator
  has_many :papers, through: :paper_originators
end
