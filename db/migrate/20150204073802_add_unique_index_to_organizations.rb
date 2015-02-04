class AddUniqueIndexToOrganizations < ActiveRecord::Migration
  def change
    add_index :organizations, :name, unique: true
  end
end
