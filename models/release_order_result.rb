# == Schema Information
#
# Table name: release_order_results
#
#  id                          :integer          not null, primary key
#  release_order_id            :integer          indexed, indexed => [env_id, application_id]
#  env_id                      :integer          indexed, indexed => [release_order_id, application_id]
#  status                      :integer          default("unknown")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  application_id              :integer          indexed => [release_order_id, env_id]
#  application_with_version_id :integer
#  log                         :text             default("")
#
# Indexes
#
#  index_release_order_results_on_env_id            (env_id)
#  index_release_order_results_on_release_order_id  (release_order_id)
#  uniq_result                                      (release_order_id,env_id,application_id) UNIQUE
#

class ReleaseOrderResult < ActiveRecord::Base
  enum status: %i[unknown success failure]

  belongs_to :release_order
  belongs_to :env
  belongs_to :application
  belongs_to :application_with_version

  def serializable_hash(_options = {})
    {
      id: id,
      application_with_version_id: application_with_version.id,
      version: application_with_version.version,
      env: env.name,
      status: status,
      deployment_date: updated_at,
      has_log: (!log.nil? && !log.empty?)
    }
  end
end
