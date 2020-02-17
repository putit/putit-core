class AddReleaseOrderResult < ActiveRecord::Migration[5.0]
  def change
    create_table :release_order_results do |t|
      t.belongs_to :release_order, index: true
      t.belongs_to :env, index: true
      t.column :status, :integer, default: 0
      t.timestamps null: false
    end
  end
end
