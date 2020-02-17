class AddSentColumnToApproval < ActiveRecord::Migration[5.0]
  def change
    add_column :approvals, :sent, :boolean, default: false
  end
end
