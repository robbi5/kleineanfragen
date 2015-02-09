class UpdateScopeInSlugIndexOfPaper < ActiveRecord::Migration
  def up
    remove_index :papers, :slug
    add_index :papers, [:body_id, :legislative_term, :slug], unique: true
  end

  def down
    remove_index :papers, [:body_id, :legislative_term, :slug]
    add_index :papers, :slug, unique: true
  end
end
