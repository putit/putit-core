class DeleteApplicationUniqOnName < ActiveRecord::Migration[5.1]
  def change
    remove_index :applications, :name
    add_index :applications, :name
  end
end
