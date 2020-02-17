class CreateApplicationVersionArtifactWithVersionsTable < ActiveRecord::Migration[5.0]
  def change
    create_table :application_version_artifact_with_versions do |t|
      t.integer :application_version_id
      t.integer :artifact_with_version_id
    end
  end
end
