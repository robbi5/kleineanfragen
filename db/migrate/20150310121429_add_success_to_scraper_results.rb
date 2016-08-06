class AddSuccessToScraperResults < ActiveRecord::Migration[4.2]
  def change
    add_column :scraper_results, :success, :boolean
  end
end
