class AddUniqueTermToLegislativeTerms < ActiveRecord::Migration[5.0]
  def change
    add_index :legislative_terms, [:body_id, :term], unique: true
  end
end
