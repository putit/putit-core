# == Schema Information
#
# Table name: envs
#
#  id             :integer          not null, primary key
#  name           :string           not null, indexed => [application_id]
#  application_id :integer          indexed, indexed => [name]
#  deleted_at     :datetime         indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  aws_tags       :string
#
# Indexes
#
#  index_envs_on_application_id           (application_id)
#  index_envs_on_deleted_at               (deleted_at)
#  index_envs_on_name_and_application_id  (name,application_id) UNIQUE
#

class Env < ActiveRecord::Base
  acts_as_paranoid

  validates_presence_of :name
  validates_uniqueness_of :name, scope: :application_id
  validates_format_of :name, with: /[\w.-]+/
  validates_format_of :aws_tags, with: %r{\A[a-zA-Z0-9!&+-=._:/@]+$?\Z}, allow_nil: :true, on: %i[create update]

  belongs_to :application
  has_many :hosts, dependent: :destroy

  has_many :events

  has_many :env_with_actions
  has_many :env_actions, through: :env_with_actions

  has_one :env_credential
  has_one :credential, through: :env_credential

  has_many :release_order_results

  has_many :pipelines, -> { order(:position) }, class_name: 'DeploymentPipeline', dependent: :destroy

  def serializable_hash(_options = {})
    { id: id,
      name: name,
      hosts: hosts,
      aws_tags: aws_tags,
      env_actions: env_actions }
  end

  # used in controller
  def get_orders(options = {})
    if options[:status] && options[:upcoming]
      @ro = ReleaseOrder.upcoming.where(status: options[:status])
      orders_by_status
    elsif options[:status] && !options.include?('upcoming')
      @ro = ReleaseOrder.where(status: options[:status])
      orders_by_status
    elsif options[:upcoming] && !options.include?('status')
      upcoming_orders
    else
      all_orders
    end
  end

  # get release orders application with version envs by state
  def orders_by_status
    avw = ApplicationWithVersion.where(application_id: application.id)
    roavw = ReleaseOrderApplicationWithVersion.where(application_with_version_id: avw.ids, release_order_id: @ro.ids)
    roavw.joins(:release_order_application_with_version_envs).select do |r|
      r.release_order_application_with_version_envs.exists?(env_id: id)
    end
  end

  # get all release orders application with version envs
  def all_orders
    avw = ApplicationWithVersion.where(application_id: application.id)
    roavw = ReleaseOrderApplicationWithVersion.where(application_with_version_id: avw.ids)
    roavw.joins(:release_order_application_with_version_envs).select do |r|
      r.release_order_application_with_version_envs.exists?(env_id: id)
    end
  end

  # get upcoming release orders application with version envs
  def upcoming_orders
    avw = ApplicationWithVersion.where(application_id: application.id)
    ro = ReleaseOrder.upcoming
    roavw = ReleaseOrderApplicationWithVersion.where(application_with_version_id: avw.ids, release_order_id: ro.ids)
    roavw.joins(:release_order_application_with_version_envs).select do |r|
      r.release_order_application_with_version_envs.exists?(env_id: id)
    end
  end

  def is_deletable?
    if upcoming_orders.empty?
      true
    else
      false
    end
  end

  def properties_key
    "/application/#{application.name}/envs/#{name}/properties"
  end
end
