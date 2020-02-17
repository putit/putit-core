class AddDeletedAtToEnv < ActiveRecord::Migration[5.1]
  def change
    add_column :envs, :deleted_at, :datetime
    add_index :envs, :deleted_at
  end
end
