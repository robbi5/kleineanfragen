class PaperOriginator < ActiveRecord::Base
  belongs_to :paper
  belongs_to :originator, polymorphic: true
end
