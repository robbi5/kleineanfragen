class AddSuccessToScraperResults < ActiveRecord::Migration
  def change
    add_column :scraper_results, :success, :boolean
  end
end
