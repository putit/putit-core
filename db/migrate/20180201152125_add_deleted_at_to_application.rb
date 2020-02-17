class AddDeletedAtToApplication < ActiveRecord::Migration[5.1]
  def change
    add_column :applications, :deleted_at, :datetime
    add_index :applications, :deleted_at
  end
end
