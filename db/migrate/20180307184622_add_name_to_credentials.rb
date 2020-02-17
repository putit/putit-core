class AddNameToCredentials < ActiveRecord::Migration[5.1]
  def change
    add_column :credentials, :name, :string
    add_index :credentials, :name
  end
end
