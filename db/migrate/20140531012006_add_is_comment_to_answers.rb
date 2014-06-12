class AddIsCommentToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :is_comment, :boolean, default: false
  end
end
