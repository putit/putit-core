class ChangeMetadataToJsonb < ActiveRecord::Migration[6.1]

  def up
    isPostgres = ActiveRecord::Migration.connection.instance_values['config'][:adapter] == 'postgresql'
    if isPostgres
      remove_column :release_orders, :metadata
      add_column :release_orders, :metadata, :jsonb, using: 'metadata::JSONB', default: {}

      remove_column :releases, :metadata
      add_column :releases, :metadata, :jsonb, using: 'metadata::JSONB', default: {}
    end
  end

  def down
    isPostgres = ActiveRecord::Migration.connection.instance_values['config'][:adapter] == 'postgresql'
    if isPostgres
      remove_column :release_orders, :metadata
      add_column :release_orders, :metadata, :string

      remove_column :releases, :metadata
      add_column :releases, :metadata, :string
    end
  end
end
