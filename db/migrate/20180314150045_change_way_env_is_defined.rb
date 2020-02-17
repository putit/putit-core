class ChangeWayEnvIsDefined < ActiveRecord::Migration[5.1]
  def change
    drop_table :envs

    create_table :envs do |t|
      t.string :name, null: false
      t.belongs_to :application, index: true
      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end

    drop_table :hosts

    create_table :hosts do |t|
      t.string :fqdn, null: false
      t.string :name
      t.string :ip
      t.belongs_to :env, index: true
      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end

    remove_column :releases, :hosts
  end
end
