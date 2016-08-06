class AddUniqueIndexToOrganizations < ActiveRecord::Migration[4.2]
  def change
    add_index :organizations, :name, unique: true
  end
end
