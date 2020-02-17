class DropTableReleaseOrderEnvs < ActiveRecord::Migration[5.1]
  def change
    drop_table :release_order_envs
  end
end
