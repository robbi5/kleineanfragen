class SetPaperIsAnswerDefaultFalse < ActiveRecord::Migration[5.0]
  def change
    change_column :papers, :is_answer, :boolean, null: false, default: false
  end
end
