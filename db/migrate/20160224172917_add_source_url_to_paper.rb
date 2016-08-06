class AddSourceUrlToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :source_url, :string
  end
end
