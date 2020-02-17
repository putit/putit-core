class AddIndexOnApprovers < ActiveRecord::Migration[5.1]
  def change
    add_index :approvals, %i[user_id release_order_id], unique: true
  end
end
