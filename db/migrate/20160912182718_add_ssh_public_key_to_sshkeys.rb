class AddSshPublicKeyToSshkeys < ActiveRecord::Migration[5.0]
  def change
    add_column :sshkeys, :ssh_public_key, :string
  end
end
