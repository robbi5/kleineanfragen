class AddPaperCountsToScraperResults < ActiveRecord::Migration
  def change
    add_column :scraper_results, :new_papers, :int
    add_column :scraper_results, :old_papers, :int
  end
end
