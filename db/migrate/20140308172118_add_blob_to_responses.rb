class AddBlobToResponses < ActiveRecord::Migration
  def change
    add_column :responses, :blob, :string
  end
end
