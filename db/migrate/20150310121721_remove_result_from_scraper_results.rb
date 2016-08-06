class RemoveResultFromScraperResults < ActiveRecord::Migration[4.2]
  def change
    remove_column :scraper_results, :result, :string
  end
end
