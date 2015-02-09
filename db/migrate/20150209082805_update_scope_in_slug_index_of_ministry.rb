class UpdateScopeInSlugIndexOfMinistry < ActiveRecord::Migration
  def up
    remove_index :ministries, :slug
    add_index :ministries, [:body_id, :slug], unique: true
  end

  def down
    remove_index :ministries, [:body_id, :slug]
    add_index :ministries, :slug, unique: true
  end
end
