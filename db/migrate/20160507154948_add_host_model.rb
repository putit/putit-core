class AddHostModel < ActiveRecord::Migration[5.0]
  def change
    create_table :hosts do |t|
      t.string :fqdn
      t.string :name
      t.string :ip
      t.timestamps null: false
    end

    create_table :host_applications do |t|
      t.belongs_to :host, index: true
      t.belongs_to :application, index: true
      t.timestamps null: false
    end
  end
end
