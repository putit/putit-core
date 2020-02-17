class AddApplicationsToReleaseOrder < ActiveRecord::Migration[5.0]
  def change
    create_table :release_order_applications do |t|
      t.belongs_to :release_order, index: true
      t.belongs_to :application, index: true
      t.timestamps null: false
    end
  end
end
