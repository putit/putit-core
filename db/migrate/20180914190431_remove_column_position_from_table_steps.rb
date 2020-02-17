class RemoveColumnPositionFromTableSteps < ActiveRecord::Migration[5.1]
  def change
    remove_column :steps, :position
  end
end
