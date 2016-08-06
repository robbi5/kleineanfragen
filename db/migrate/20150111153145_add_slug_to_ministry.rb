class AddSlugToMinistry < ActiveRecord::Migration[4.2]
  def change
    add_column :ministries, :slug, :string
    add_index :ministries, :slug, unique: true
  end
end
