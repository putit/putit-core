class ChangeUuidSettingForApprovals < ActiveRecord::Migration[5.0]
  def change
    create_table :approvals, force: true do |t|
      t.string     :name
      t.string     :uuid, limit: 36, index: true
      t.string     :email
      t.boolean    :accepted, default: false
      t.belongs_to :release_order
      t.belongs_to :user
      t.timestamps null: false
    end
  end
end
