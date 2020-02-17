class CreateApplicatonsVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :applications_versions do |t|
      t.belongs_to :application, index: true
      t.string :version
      t.timestamps null: false
    end
  end
end
