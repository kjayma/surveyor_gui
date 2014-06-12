class AddColumnIdToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :column_id, :integer
  end
end
