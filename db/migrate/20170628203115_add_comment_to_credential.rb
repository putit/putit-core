class AddCommentToCredential < ActiveRecord::Migration[5.0]
  def change
    add_column :credentials, :comment, :string
  end
end
