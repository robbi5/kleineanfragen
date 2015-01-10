class PaperAnswerer < ActiveRecord::Base
  belongs_to :paper
  belongs_to :answerer, polymorphic: true
end
