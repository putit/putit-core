class AddUniqToNameApplication < ActiveRecord::Migration[5.1]
  def change
    add_index :applications, :name, unique: true
  end
end
