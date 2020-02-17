class ChangePipelineColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :deployment_pipelines, :application_id
    add_column :deployment_pipelines, :env_id, :integer
    add_column :deployment_pipelines, :position, :integer
    add_column :deployment_pipelines, :template, :boolean, default: true
    add_column :deployment_pipelines, :deleted_at, :datetime
    add_index :deployment_pipelines, :deleted_at

    add_column :deployment_pipeline_steps, :position, :integer
  end
end
