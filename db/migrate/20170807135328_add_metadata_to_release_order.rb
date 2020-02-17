class AddMetadataToReleaseOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :release_orders, :metadata, :string, default: '{}'
  end
end
