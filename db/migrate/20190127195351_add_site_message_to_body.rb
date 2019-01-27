class AddSiteMessageToBody < ActiveRecord::Migration[5.0]
  def change
    add_column :bodies, :site_message, :text
  end
end
