class AddReleaseOrderEnvs < ActiveRecord::Migration[5.0]
  def change
    create_table :release_order_envs do |t|
      t.belongs_to :release_order, index: true
      t.belongs_to :env, index: true

      t.timestamps null: false
    end
  end
end
