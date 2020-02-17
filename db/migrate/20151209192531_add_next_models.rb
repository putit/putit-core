class AddNextModels < ActiveRecord::Migration[5.0]
  def change
    create_table :applications do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :application_artifacts do |t|
      t.belongs_to :application, index: true
      t.belongs_to :artifact, index: true
      t.timestamps null: false
    end
  end
end
