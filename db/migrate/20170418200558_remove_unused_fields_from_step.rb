class RemoveUnusedFieldsFromStep < ActiveRecord::Migration[5.0]
  def change
    remove_columns(:steps, :yaml_template, :operates_on_artifact)
  end
end
