class AddContainsTableToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :contains_table, :boolean
  end
end
