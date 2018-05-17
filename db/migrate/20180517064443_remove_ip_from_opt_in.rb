class RemoveIpFromOptIn < ActiveRecord::Migration[5.0]
  def change
    remove_column :opt_ins, :confirmed_ip, :string
    remove_column :opt_ins, :created_ip, :string
  end
end
