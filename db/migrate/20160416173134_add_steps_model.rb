class AddStepsModel < ActiveRecord::Migration[5.0]
  def change
    create_table :steps do |t|
      t.string     :name
      t.text       :description
      t.boolean    :template
      t.boolean    :operates_on_artifact
      t.text       :yaml_template
      t.text       :properties_description
      t.belongs_to :application, index: true
      t.timestamps null: false
    end
  end
end
