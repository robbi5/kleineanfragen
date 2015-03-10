class AddMessageToScraperResults < ActiveRecord::Migration
  def change
    add_column :scraper_results, :message, :string
  end
end
