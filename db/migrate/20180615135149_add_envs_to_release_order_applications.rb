class AddEnvsToReleaseOrderApplications < ActiveRecord::Migration[5.1]
  def change
    create_table :release_order_application_with_version_envs do |t|
      t.belongs_to :release_order_application_with_version, index: { name: 'env_ro_avw' }
      t.belongs_to :env, index: { name: 'env_ro_env' }
      t.timestamps null: false
    end
  end
end
