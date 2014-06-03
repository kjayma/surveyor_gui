class AddColumnIdToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :column_id, :integer
  end
end
