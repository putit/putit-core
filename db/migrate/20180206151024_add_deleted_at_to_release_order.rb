class AddDeletedAtToReleaseOrder < ActiveRecord::Migration[5.1]
  def change
    add_column :release_orders, :deleted_at, :datetime
    add_index :release_orders, :deleted_at
  end
end
