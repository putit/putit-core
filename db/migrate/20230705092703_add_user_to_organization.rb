class AddUserToOrganization < ActiveRecord::Migration[7.0]
  def connection
    User.connection
  end

  def change
    add_belongs_to :users, :organization
  end
end
