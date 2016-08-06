class AddIsAnswerToPaper < ActiveRecord::Migration[4.2]
  def change
    add_column :papers, :is_answer, :bool
  end
end
