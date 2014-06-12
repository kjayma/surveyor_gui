class AddColumnIdToDependencyConditions < ActiveRecord::Migration
  def change
    add_column :dependency_conditions, :column_id, :integer
  end
end
