class RenameApplicationVersionToApplicationWithVersion < ActiveRecord::Migration[5.0]
  def change
    rename_table :application_versions, :application_with_versions
    rename_table :application_version_artifact_with_versions, :application_with_version_artifact_with_versions
    rename_table :release_order_application_versions, :release_order_application_with_versions

    rename_column :application_with_version_artifact_with_versions, :application_version_id, :application_with_version_id
    rename_column :release_order_application_with_versions, :application_version_id, :application_with_version_id
  end
end
