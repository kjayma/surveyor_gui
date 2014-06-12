class AddOriginalChoiceToAnswers < ActiveRecord::Migration
  def change
    add_column :answers, :original_choice, :string
  end
end
