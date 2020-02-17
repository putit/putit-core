class ChangeApplicationWithVersionsColumns < ActiveRecord::Migration[5.1]
  def change
    add_column :application_with_versions, :deleted_at, :datetime
    add_index :application_with_versions, :deleted_at
  end
end
