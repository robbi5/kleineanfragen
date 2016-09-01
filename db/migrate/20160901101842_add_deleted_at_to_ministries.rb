class AddDeletedAtToMinistries < ActiveRecord::Migration[5.0]
  def change
    add_column :ministries, :deleted_at, :datetime
    add_index :ministries, :deleted_at
  end
end
