class AddColumnAwsTagsToEnvs < ActiveRecord::Migration[5.1]
  def change
    add_column :envs, :aws_tags, :string
  end
end
