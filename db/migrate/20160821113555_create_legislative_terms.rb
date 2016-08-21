class CreateLegislativeTerms < ActiveRecord::Migration[5.0]
  def change
    create_table :legislative_terms do |t|
      t.references :body, foreign_key: true
      t.integer :term
      t.date :starts_at
      t.date :ends_at

      t.timestamps
    end
  end
end
