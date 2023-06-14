class AddApplicationToOrganization < ActiveRecord::Migration[7.0]
  def change
    add_belongs_to :applications, :organization
  end
end
