class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.string :email
      t.integer :type
      t.string :query
      t.boolean :active
      t.datetime :last_sent_at

      t.timestamps null: false
    end
  end
end
