class AddTestDataToResponseSets < ActiveRecord::Migration
  def change
    add_column :response_sets, :test_data, :boolean, :default=>false
  end
end
