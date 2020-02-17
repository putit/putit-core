# == Schema Information
#
# Table name: application_with_version_artifact_with_versions
#
#  id                          :integer          not null, primary key
#  application_with_version_id :integer
#  artifact_with_version_id    :integer
#

class ApplicationWithVersionArtifactWithVersion < ActiveRecord::Base
  belongs_to :artifact_with_version
  belongs_to :application_with_version
end
