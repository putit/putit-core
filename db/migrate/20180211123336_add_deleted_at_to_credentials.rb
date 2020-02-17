class AddDeletedAtToCredentials < ActiveRecord::Migration[5.1]
  def change
    add_column :credentials, :deleted_at, :datetime
    add_index :credentials, :deleted_at
  end
end
