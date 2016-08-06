class AddPdfLastModifiedToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :pdf_last_modified, :datetime
  end
end
