class CreatePapers < ActiveRecord::Migration[4.2]
  def change
    create_table :papers do |t|
      t.references :body, index: true
      t.integer :legislative_term
      t.text :reference
      t.text :title
      t.text :contents
      t.integer :page_count
      t.text :url
      t.date :published_at
      t.datetime :downloaded_at

      t.timestamps
    end

    add_index :papers, [:body_id, :legislative_term, :reference], unique: true
  end
end
