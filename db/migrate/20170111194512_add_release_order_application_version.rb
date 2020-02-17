class AddReleaseOrderApplicationVersion < ActiveRecord::Migration[5.0]
  def change
    create_table :release_order_application_versions do |t|
      t.integer :release_order_id
      t.integer :application_version_id
    end
  end
end
