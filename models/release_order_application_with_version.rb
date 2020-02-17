# == Schema Information
#
# Table name: release_order_application_with_versions
#
#  id                          :integer          not null, primary key
#  release_order_id            :integer
#  application_with_version_id :integer
#

class ReleaseOrderApplicationWithVersion < ActiveRecord::Base
  belongs_to :release_order
  belongs_to :application_with_version

  has_many :release_order_application_with_version_envs, dependent: :destroy
  has_many :envs, through: :release_order_application_with_version_envs

  def serializable_hash(_options = {})
    envs = release_order_application_with_version_envs.map(&:env).map do |env|
      {
        'id': env.id,
        'name': env.name
      }
    end
    result = {
      application_with_version: application_with_version,
      envs: envs
    }
    result
  end
end
