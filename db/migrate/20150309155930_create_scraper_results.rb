class CreateScraperResults < ActiveRecord::Migration[4.2]
  def change
    create_table :scraper_results do |t|
      t.references :body
      t.timestamp :started_at
      t.timestamp :stopped_at
      t.string :result

      t.timestamps null: false
    end
  end
end
