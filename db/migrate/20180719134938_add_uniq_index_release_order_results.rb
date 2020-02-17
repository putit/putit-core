class AddUniqIndexReleaseOrderResults < ActiveRecord::Migration[5.1]
  def change
    add_index :release_order_results, %i[release_order_id env_id application_id], unique: true, name: 'uniq_result'
  end
end
