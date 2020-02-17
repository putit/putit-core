class AddArchiveColumnToReleaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :release_orders, :archive, :binary
  end
end
