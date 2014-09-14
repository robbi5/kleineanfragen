class AddSlugToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :slug, :string
    add_index :papers, :slug, unique: true
  end
end
