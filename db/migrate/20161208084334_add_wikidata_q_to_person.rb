class AddWikidataQToPerson < ActiveRecord::Migration[5.0]
  def change
    add_column :people, :wikidataq, :string
  end
end
