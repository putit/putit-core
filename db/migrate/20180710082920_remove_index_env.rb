class RemoveIndexEnv < ActiveRecord::Migration[5.1]
  def change
    remove_index :envs, column: %i[id application_id]
  end
end
