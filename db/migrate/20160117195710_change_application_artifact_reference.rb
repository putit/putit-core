class ChangeApplicationArtifactReference < ActiveRecord::Migration[5.0]
  def change
    rename_column :application_artifacts, :artifact_id, :artifact_with_version_id
  end
end
