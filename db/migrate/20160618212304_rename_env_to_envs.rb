class RenameEnvToEnvs < ActiveRecord::Migration[5.0]
  def change
    rename_table :env, :envs
  end
end
