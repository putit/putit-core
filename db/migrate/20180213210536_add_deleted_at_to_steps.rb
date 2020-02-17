class AddDeletedAtToSteps < ActiveRecord::Migration[5.1]
  def change
    add_column :steps, :deleted_at, :datetime
    add_index :steps, :deleted_at
  end
end
