class AddUniqIndexNameAndApplicationIdEnv < ActiveRecord::Migration[5.1]
  def change
    add_index :envs, %i[name application_id], unique: true
  end
end
