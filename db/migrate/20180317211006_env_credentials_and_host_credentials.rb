class EnvCredentialsAndHostCredentials < ActiveRecord::Migration[5.1]
  def change
    create_table :env_credentials do |t|
      t.belongs_to :env, index: true
      t.belongs_to :credential, index: true
      t.timestamps
    end

    create_table :host_credentials do |t|
      t.belongs_to :host, index: true
      t.belongs_to :credential, index: true
      t.timestamps
    end
  end
end
