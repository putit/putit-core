class AddPositionToSteps < ActiveRecord::Migration[5.0]
  def change
    add_column :steps, :position, :integer
  end
end
