class AddOrganizationTable < ActiveRecord::Migration[7.0]
  def change
    create_table :organizations do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
