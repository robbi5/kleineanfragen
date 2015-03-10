class RemoveResultFromScraperResults < ActiveRecord::Migration
  def change
    remove_column :scraper_results, :result, :string
  end
end
