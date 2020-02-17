class AddDeploymentPipeline < ActiveRecord::Migration[5.0]
  def change
    create_table :deployment_pipelines do |t|
      t.belongs_to :application, index: true, unique: true
      t.timestamps null: false
    end

    create_table :deployment_pipeline_steps do |t|
      t.belongs_to :deployment_pipeline, index: true
      t.belongs_to :step, index: true
      t.timestamps null: false
    end

    remove_column(:steps, :application_id)
  end
end
