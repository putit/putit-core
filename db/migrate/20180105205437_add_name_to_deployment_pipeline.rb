class AddNameToDeploymentPipeline < ActiveRecord::Migration[5.1]
  def change
    add_column :deployment_pipelines, :name, :string
    add_index :deployment_pipelines, :name
  end
end
