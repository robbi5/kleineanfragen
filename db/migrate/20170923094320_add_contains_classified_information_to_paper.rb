class AddContainsClassifiedInformationToPaper < ActiveRecord::Migration[5.0]
  def change
    add_column :papers, :contains_classified_information, :boolean
  end
end
