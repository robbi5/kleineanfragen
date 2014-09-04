class CreateBodies < ActiveRecord::Migration
  def change
    create_table :bodies do |t|
      t.text :name
      t.string :state, limit: 2
      t.text :website

      t.timestamps
    end

    add_index :bodies, :name, unique: true
    add_index :bodies, :state, unique: true
  end
end
