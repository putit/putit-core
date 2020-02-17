class AddReleaseModel < ActiveRecord::Migration[5.0]
  def change
    create_table :releases do |t|
      t.string :name
      t.string :hosts
      t.timestamps null: false
    end

    create_table :release_applications do |t|
      t.belongs_to :release, index: true
      t.belongs_to :application, index: true
      t.timestamps null: false
    end
  end
end
