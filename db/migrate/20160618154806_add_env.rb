class AddEnv < ActiveRecord::Migration[5.0]
  def change
    create_table :env do |t|
      t.string :name, null: false
      t.timestamps null: false
    end
    create_table :env_application_credentials do |t|
      t.belongs_to :env, index: true
      t.belongs_to :application, index: true
      t.belongs_to :credential, index: true
      t.timestamps null: false
    end
    create_table :env_host_credentials do |t|
      t.belongs_to :env, index: true
      t.belongs_to :host, index: true
      t.belongs_to :credential, index: true
      t.timestamps null: false
    end
  end
end
