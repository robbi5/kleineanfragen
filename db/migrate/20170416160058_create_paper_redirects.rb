class CreatePaperRedirects < ActiveRecord::Migration[5.0]
  def change
    create_table :paper_redirects do |t|
      t.references :body, foreign_key: true, null: false
      t.integer :legislative_term
      t.text :reference
      t.references :paper, index: true, foreign_key: true, null: false

      t.timestamps
    end
  end
end
