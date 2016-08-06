class AddPaperCountsToScraperResults < ActiveRecord::Migration[4.2]
  def change
    add_column :scraper_results, :new_papers, :int
    add_column :scraper_results, :old_papers, :int
  end
end
