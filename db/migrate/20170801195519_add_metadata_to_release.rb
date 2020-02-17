class AddMetadataToRelease < ActiveRecord::Migration[5.0]
  def change
    add_column :releases, :metadata, :string, default: '{}'
  end
end
