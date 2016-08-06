class AddContainsTableToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :contains_table, :boolean
  end
end
