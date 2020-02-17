class AddAnsibleTables < ActiveRecord::Migration[5.0]
  TABLES = %w[files templates handlers tasks vars defaults]

  def change
    TABLES.each do |table|
      create_table 'ansible_' + table do |t|
        t.belongs_to :step, index: true, unique: true
        t.timestamps null: false
      end
    end

    create_table :physical_files do |t|
      t.string :name
      t.binary :content
      t.references :fileable, polymorphic: true, index: true
      t.timestamps null: false
    end
  end
end
