class PaperAnswerer < ApplicationRecord
  belongs_to :paper
  belongs_to :answerer, polymorphic: true
end
