class AddWikidataQToBody < ActiveRecord::Migration[5.0]
  def change
    add_column :bodies, :wikidataq, :string
  end
end
