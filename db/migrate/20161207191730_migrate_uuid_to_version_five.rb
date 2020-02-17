class MigrateUuidToVersionFive < ActiveRecord::Migration[5.0][5.0]
  def change
    change_table :approvals, id: :uuid do
    end
  end
end
