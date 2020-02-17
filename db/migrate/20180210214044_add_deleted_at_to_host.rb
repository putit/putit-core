class AddDeletedAtToHost < ActiveRecord::Migration[5.1]
  def change
    add_column :hosts, :deleted_at, :datetime
    add_index :hosts, :deleted_at
  end
end
