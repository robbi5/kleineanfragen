class CreatePeople < ActiveRecord::Migration[4.2]
  def change
    create_table :people do |t|
      t.text :name
      t.text :party

      t.timestamps
    end
  end
end
