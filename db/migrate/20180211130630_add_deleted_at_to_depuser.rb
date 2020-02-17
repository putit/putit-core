class AddDeletedAtToDepuser < ActiveRecord::Migration[5.1]
  def change
    add_column :depusers, :deleted_at, :datetime
    add_index :depusers, :deleted_at
  end
end
