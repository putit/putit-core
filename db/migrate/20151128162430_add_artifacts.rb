class AddArtifacts < ActiveRecord::Migration[5.0]
  def change
    create_table :artifacts do |t|
      t.string :name
      t.timestamps null: false
    end

    create_table :versions do |t|
      t.belongs_to :artifact, index: true
      t.string :version
      t.timestamps null: false
    end
  end
end
