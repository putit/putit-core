class AddEnabledToEnvAction < ActiveRecord::Migration[5.1]
  def change
    add_column :env_actions, :enabled, :boolean, default: true
  end
end
