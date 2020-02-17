# == Schema Information
#
# Table name: depusers
#
#  id         :integer          not null, primary key
#  username   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime         indexed
#
# Indexes
#
#  index_depusers_on_deleted_at  (deleted_at)
#

class Depuser < ActiveRecord::Base
  acts_as_paranoid

  has_many :credentials
  has_many :sshkeys, through: :credentials

  validates_presence_of :username
  # man 8 useradd CAVEATS section
  validates_format_of :username, with: /\A[a-z_][a-z0-9_-]*[$]?\Z/

  def serializable_hash(_options = {})
    { id: id,
      username: username }
  end
end
