class CreateArtifactWithVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :artifact_with_versions do |t|
      t.integer :artifact_id
      t.integer :version_id
      t.timestamps null: false
    end
  end
end
