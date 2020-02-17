class AddDeletedAtToApprovals < ActiveRecord::Migration[5.1]
  def change
    add_column :approvals, :deleted_at, :datetime
    add_index :approvals, :deleted_at
  end
end
