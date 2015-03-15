class RenameSubscriptionTypeColumn < ActiveRecord::Migration
  def change
    rename_column :subscriptions, :type, :subtype
  end
end
