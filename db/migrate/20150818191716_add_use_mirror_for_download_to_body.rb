class AddUseMirrorForDownloadToBody < ActiveRecord::Migration[4.2]
  def change
    add_column :bodies, :use_mirror_for_download, :boolean, default: false
  end
end
