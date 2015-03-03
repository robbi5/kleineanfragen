class AddDocTypeToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :doctype, :string
  end
end
