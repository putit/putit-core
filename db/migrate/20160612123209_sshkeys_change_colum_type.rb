class SshkeysChangeColumType < ActiveRecord::Migration[5.0]
  def change
    rename_column :sshkeys, :type, :keytype
  end
end
