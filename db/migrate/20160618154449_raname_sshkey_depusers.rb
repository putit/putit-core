class RanameSshkeyDepusers < ActiveRecord::Migration[5.0]
  def change
    rename_table :sshkey_depusers, :credentials
  end
end
