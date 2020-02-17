class RemoveUnnededTables < ActiveRecord::Migration[5.0]
  def change
    drop_tables

    rename_applications_versions
  end

  private

  def drop_tables
    drop_table :application_artifacts
    drop_table :release_applications
    drop_table :release_order_applications
  end

  def rename_applications_versions
    rename_table :applications_versions, :application_versions
  end
end
