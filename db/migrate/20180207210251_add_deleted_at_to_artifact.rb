class AddDeletedAtToArtifact < ActiveRecord::Migration[5.1]
  def change
    add_column :artifacts, :deleted_at, :datetime
    add_index :artifacts, :deleted_at
  end
end
