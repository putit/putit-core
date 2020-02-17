class AddDescriptionsToPipelines < ActiveRecord::Migration[5.1]
  def change
    add_column :deployment_pipelines, :description, :text
  end
end
