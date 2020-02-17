class RemoveExtensionFromArtifact < ActiveRecord::Migration[5.1]
  def change
    remove_column :artifacts, :extension
  end
end
