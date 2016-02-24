class AddSourceUrlToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :source_url, :string
  end
end
