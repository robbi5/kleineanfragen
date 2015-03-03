class AddIsAnswerToPaper < ActiveRecord::Migration
  def change
    add_column :papers, :is_answer, :bool
  end
end
