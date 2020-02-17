class AddExtensionToArtifacts < ActiveRecord::Migration[5.0]
  def change
    add_column :artifacts, :extension, :string, default: false
  end
end
