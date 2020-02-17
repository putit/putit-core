class AddUniqToHostFqdnAndEnvId < ActiveRecord::Migration[5.1]
  def change
    add_index :hosts, %i[fqdn env_id], unique: true
  end
end
