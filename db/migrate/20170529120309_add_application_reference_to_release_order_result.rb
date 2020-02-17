class AddApplicationReferenceToReleaseOrderResult < ActiveRecord::Migration[5.0]
  def change
    add_column :release_order_results, :application_id, :integer
    add_column :release_order_results, :application_with_version_id, :integer
  end
end
