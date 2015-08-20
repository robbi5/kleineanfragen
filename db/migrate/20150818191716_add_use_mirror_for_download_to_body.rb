class AddUseMirrorForDownloadToBody < ActiveRecord::Migration
  def change
    add_column :bodies, :use_mirror_for_download, :boolean, default: false
  end
end
