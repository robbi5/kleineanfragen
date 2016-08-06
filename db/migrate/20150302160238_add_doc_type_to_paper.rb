class AddDocTypeToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :doctype, :string
  end
end
