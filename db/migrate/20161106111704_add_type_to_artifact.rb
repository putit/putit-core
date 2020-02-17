class AddTypeToArtifact < ActiveRecord::Migration[5.0]
  def change
    add_column :artifacts, :artifact_type, :integer, default: 0
  end
end
