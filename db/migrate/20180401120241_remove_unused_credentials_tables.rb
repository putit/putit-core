class RemoveUnusedCredentialsTables < ActiveRecord::Migration[5.1]
  def change
    drop_table :env_host_credentials
    drop_table :env_application_credentials
  end
end
