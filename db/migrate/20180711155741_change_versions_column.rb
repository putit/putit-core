class ChangeVersionsColumn < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :deleted_at, :datetime
    add_index :versions, :deleted_at
  end
end
