class RenameSubscriptionTypeColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :subscriptions, :type, :subtype
  end
end
