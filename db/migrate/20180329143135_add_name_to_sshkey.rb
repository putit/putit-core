class AddNameToSshkey < ActiveRecord::Migration[5.1]
  def change
    add_column :sshkeys, :name, :string
    add_index :sshkeys, :name
  end
end
