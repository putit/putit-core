# == Schema Information
#
# Table name: application_with_versions
#
#  id             :integer          not null, primary key
#  application_id :integer
#  version        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  deleted_at     :datetime
#

class ApplicationWithVersion < ActiveRecord::Base
  acts_as_paranoid
  belongs_to :application

  has_many :release_order_application_with_versions
  has_many :release_orders, through: :release_order_application_with_versions

  has_many :application_with_version_artifact_with_versions
  has_many :artifact_with_versions, through: :application_with_version_artifact_with_versions

  has_many :release_order_results

  has_paper_trail version: :paper_trail_version,
                  versions: { class_name: 'PaperTrailVersion',
                              name: :paper_trail_versions }

  def dir_name
    "#{application.name.gsub(' ', '_')}-#{version}"
  end

  def serializable_hash(options = {})
    awv = { id: id,
            name: application.name,
            artifacts: artifact_with_versions,
            version: version }

    orders = {
      last_deployments: get_last_deployments,
      upcoming_deployments: get_upcoming_deployments
    }
    awv.merge!(orders) if !options.nil? && options[:with_release_orders]
    awv
  end

  def get_last_deployments
    deployment_results = []
    application.envs.each do |app_env|
      deployment_results << DeploymentStatusService.new.get_deployment_status(self, app_env)
    end
    deployment_results.compact
  end

  def get_upcoming_deployments
    roavws = ReleaseOrderApplicationWithVersion.where(application_with_version_id: id).joins(:release_order).merge(ReleaseOrder.upcoming)
    roavws.map do |roavw|
      {
        release: roavw.release_order.release.name,
        change: roavw.release_order.name,
        envs: roavw.release_order_application_with_version_envs.map(&:env).map(&:name).join(', '),
        deployment_date: roavw.release_order.start_date
      }
    end
  end
end
