class CreateOptIns < ActiveRecord::Migration
  def change
    create_table :opt_ins do |t|
      t.string :email
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.string :confirmed_ip
      t.string :created_ip

      t.timestamps null: false
    end
  end
end
