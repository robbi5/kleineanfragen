class AddShortNameToMinistry < ActiveRecord::Migration[4.2]
  def change
    add_column :ministries, :short_name, :string
  end
end
