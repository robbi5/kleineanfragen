class AddDeletedAtToPeople < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :deleted_at, :datetime
    add_index :people, :deleted_at
  end
end
