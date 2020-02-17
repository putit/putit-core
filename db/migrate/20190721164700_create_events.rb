class CreateEvents < ActiveRecord::Migration[5.1]
  def change
    isSqlite = ActiveRecord::Migration.connection.instance_values['config'][:adapter] == 'sqlite3'
    create_table :events do |t|
      t.belongs_to :env, index: true
      t.string :source
      t.integer :status
      t.integer :severity
      t.string  :uuid, limit: 36, index: true
      if isSqlite
        t.string :data
      else
        t.jsonb :data
      end
      t.integer :event_type, default: 1
      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end

    create_table :env_actions do |t|
      t.integer :env_action_id, index: true
      t.string  :uuid, limit: 36, index: true
      if isSqlite
        t.string :data
      else
        t.jsonb :data
      end
      t.integer :status, default: 0
      t.string  :name
      t.string  :description
      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end

    create_table :env_with_actions do |t|
      t.belongs_to :env, index: true
      t.belongs_to :env_action, index: true
      t.timestamps null: false
    end
  end
end
