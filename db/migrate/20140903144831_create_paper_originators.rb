class CreatePaperOriginators < ActiveRecord::Migration
  def change
    create_table :paper_originators do |t|
      t.references :paper, index: true
      t.references :originator, polymorphic: true, index: true
    end
  end
end
