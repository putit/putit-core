class AddStatusToReleaseOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :release_orders, :status, :integer
  end
end
