class AddScraperClassToScraperResults < ActiveRecord::Migration[4.2]
  def change
    add_column :scraper_results, :scraper_class, :string
  end
end
