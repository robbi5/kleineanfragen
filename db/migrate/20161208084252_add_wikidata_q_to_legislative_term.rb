class AddWikidataQToLegislativeTerm < ActiveRecord::Migration[5.0]
  def change
    add_column :legislative_terms, :wikidataq, :string
  end
end
