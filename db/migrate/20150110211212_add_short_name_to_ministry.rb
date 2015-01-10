class AddShortNameToMinistry < ActiveRecord::Migration
  def change
    add_column :ministries, :short_name, :string
  end
end
