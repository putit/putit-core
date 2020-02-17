class AddNameToReleaseOrders < ActiveRecord::Migration[5.0]
  def change
    add_column :release_orders, :name, :string
    add_index :release_orders, :name
  end
end
