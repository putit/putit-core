class AddLogsToReleaseOrderResult < ActiveRecord::Migration[5.0]
  def change
    add_column :release_order_results, :log, :text, default: ''
  end
end
