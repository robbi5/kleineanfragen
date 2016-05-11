class AddScraperClassToScraperResults < ActiveRecord::Migration
  def change
    add_column :scraper_results, :scraper_class, :string
  end
end
