class AddColumnStatusToRelease < ActiveRecord::Migration[5.0]
  def change
    add_column :releases, :status, :integer
  end
end
