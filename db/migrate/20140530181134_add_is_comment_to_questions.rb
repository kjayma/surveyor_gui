class AddIsCommentToQuestions < ActiveRecord::Migration
  def change
    add_column :questions, :is_comment, :boolean, default: false
  end
end
