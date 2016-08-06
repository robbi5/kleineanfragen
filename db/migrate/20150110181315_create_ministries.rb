class CreateMinistries < ActiveRecord::Migration[4.2]
  def change
    create_table :ministries do |t|
      t.references :body, index: true
      t.string :name

      t.timestamps null: false
    end
    add_foreign_key :ministries, :bodies
    add_index :ministries, [:body_id, :name], unique: true
  end
end
