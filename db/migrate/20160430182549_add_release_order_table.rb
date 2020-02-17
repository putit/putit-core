class AddReleaseOrderTable < ActiveRecord::Migration[5.0]
  def change
    create_table :release_orders do |t|
      t.datetime   :start_date
      t.datetime   :end_date
      t.text       :description
      t.belongs_to :release, index: true
      t.timestamps null: false
    end
  end
end
