# == Schema Information
#
# Table name: artifacts
#
#  id            :integer          not null, primary key
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  artifact_type :integer          default("flat")
#  deleted_at    :datetime         indexed
#
# Indexes
#
#  index_artifacts_on_deleted_at  (deleted_at)
#

class Artifact < ActiveRecord::Base
  acts_as_paranoid

  include Putit::ActiveRecordLogging

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_format_of :name, with: /\A[a-z0-9\-\_]+$?\Z/

  enum artifact_type: %i[flat github_repository github_release]

  attr_accessor :properties

  has_many :versions

  before_destroy do
    ArtifactWithVersion.where(artifact_id: id).each(&:destroy)
  end

  self.inheritance_column = 'subtype'

  def full_name
    name
  end

  def serializable_hash(_options = {})
    awv = ArtifactWithVersion.find_by_artifact_id_and_version_id(id, versions.last.id)
    properties = PROPERTIES_STORE.fetch(awv.properties_key, {})
    hash = { id: id,
             name: name,
             version: versions.last.version,
             version_id: versions.last.id,
             properties: properties,
             versions: versions }
  end
end
