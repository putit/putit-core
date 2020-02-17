class AddApprovals < ActiveRecord::Migration[5.0]
  def change
    create_table :approvals, id: false do |t|
      t.binary     :id, primary_key: true, limit: 16
      t.string     :name
      t.string     :email
      t.boolean    :accepted, default: false
      t.belongs_to :release_order
      t.timestamps null: false
    end
  end
end
