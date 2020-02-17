class AddIndexOnDeploymentPipelineStep < ActiveRecord::Migration[5.1]
  def change
    add_index :deployment_pipeline_steps, %i[deployment_pipeline_id step_id], unique: true, name: 'step_pipeline_index'
  end
end
