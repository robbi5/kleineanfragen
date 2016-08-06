class AddUniqueIndexToPeople < ActiveRecord::Migration[4.2]
  def change
    add_index :people, :name, unique: true
  end
end
