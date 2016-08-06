class AddMessageToScraperResults < ActiveRecord::Migration[4.2]
  def change
    add_column :scraper_results, :message, :string
  end
end
