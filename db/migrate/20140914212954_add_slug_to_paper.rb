class AddSlugToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :slug, :string
    add_index :papers, :slug, unique: true
  end
end
