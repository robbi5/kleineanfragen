class AddSlugToBody < ActiveRecord::Migration
  def change
    add_column :bodies, :slug, :string
    add_index :bodies, :slug, unique: true
  end
end
