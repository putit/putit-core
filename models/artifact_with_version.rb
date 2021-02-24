# == Schema Information
#
# Table name: artifact_with_versions
#
#  id          :integer          not null, primary key
#  artifact_id :integer
#  version_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class ArtifactWithVersion < ActiveRecord::Base
  belongs_to :artifact
  belongs_to :version

  attr_accessor :properties

  before_destroy do
    PROPERTIES_STORE.delete(properties_key)
  end

  def properties_key
    key = "#{artifact.name}/#{version.version}"
    "/artifact/#{artifact.artifact_type}/#{key}/properties"
  end

  def serializable_hash(_options = {})
    { 'id' => id,
      'name' => artifact.name,
      'version' => version.version }
  end

  def to_s
    "#{artifact.name} with version: #{version.version}"
  end
end
