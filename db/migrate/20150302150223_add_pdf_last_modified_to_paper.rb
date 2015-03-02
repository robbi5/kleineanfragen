class AddPdfLastModifiedToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :pdf_last_modified, :datetime
  end
end
