# == Schema Information
#
# Table name: applications
#
#  id         :integer          not null, primary key
#  name       :string           indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime         indexed
#
# Indexes
#
#  index_applications_on_deleted_at  (deleted_at)
#  index_applications_on_name        (name)
#

class Application < ActiveRecord::Base
  acts_as_paranoid

  validates_presence_of :name

  include Putit::ActiveRecordLogging

  has_many :envs, dependent: :destroy

  has_many :versions, class_name: 'ApplicationWithVersion', dependent: :destroy

  has_many :release_order_results

  has_paper_trail versions: { class_name: 'PaperTrailVersion', 
                              name: :paper_trail_versions }

  def serializable_hash(options = {})
    result = super(options)

    result[:versions] = versions.map(&:version)
    result[:last_deployments] = get_last_deployments
    result[:upcoming_deployments] = upcoming_orders

    result
  end

  # returns current deployed versions per env
  def get_last_deployments
    deployment_results = []
    envs.each do |app_env|
      deployment_results << DeploymentStatusService.new.get_deployment_status(self, app_env)
    end
    deployment_results.compact
  end

  def upcoming_orders
    ReleaseOrder.upcoming.joins(:application_with_versions)
                .where('application_with_versions.application_id = ?', id)
                .order(:start_date)
  end

  def is_deletable?
    if upcoming_orders.empty?
      true
    else
      false
    end
  end

  def dir_name
    name.gsub(' ', '_')
  end

  def url_name
    name.gsub(' ', '%20')
  end
end
