class CreateEmailBlacklists < ActiveRecord::Migration[4.2]
  def change
    create_table :email_blacklists do |t|
      t.string :email
      t.integer :reason
      t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
