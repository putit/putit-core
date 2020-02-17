class AddPaperTrailTables < ActiveRecord::Migration[5.0]
  def change
    create_table :paper_trail_versions do |t|
      t.string :item_type
      t.integer  :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.text     :object
      t.datetime :created_at
    end

    add_index :paper_trail_versions, %i[item_type item_id]

    create_table :version_associations do |t|
      t.integer  :version_id
      t.string   :foreign_key_name, null: false
      t.integer  :foreign_key_id
    end
    add_index :version_associations, [:version_id]
    add_index :version_associations,
              %i[foreign_key_name foreign_key_id],
              name: 'index_version_associations_on_foreign_key'
  end
end
