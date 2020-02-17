class AddDeletedAtToSshkeys < ActiveRecord::Migration[5.1]
  def change
    add_column :sshkeys, :deleted_at, :datetime
    add_index :sshkeys, :deleted_at
  end
end
