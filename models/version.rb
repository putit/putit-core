# == Schema Information
#
# Table name: versions
#
#  id          :integer          not null, primary key
#  artifact_id :integer          indexed
#  version     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime         indexed
#
# Indexes
#
#  index_versions_on_artifact_id  (artifact_id)
#  index_versions_on_deleted_at   (deleted_at)
#

class Version < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :artifact

  validates_presence_of :version
  validates_format_of :version, with: /\A[\w\-.]+$?\Z/

  def serializable_hash(_options = {})
    { version: version }
  end
end
