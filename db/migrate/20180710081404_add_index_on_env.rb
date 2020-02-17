class AddIndexOnEnv < ActiveRecord::Migration[5.1]
  def change
    add_index :envs, %i[id application_id], unique: true
  end
end
