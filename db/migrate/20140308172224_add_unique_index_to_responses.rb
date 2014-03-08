class AddUniqueIndexToResponses < ActiveRecord::Migration
  def change
    add_index(:responses, [:response_set_id, :question_id, :answer_id], :name => 'response_unique_idx', :unique => true)
  end
end
