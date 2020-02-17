# == Schema Information
#
# Table name: release_orders
#
#  id          :integer          not null, primary key
#  start_date  :datetime
#  end_date    :datetime
#  description :text
#  release_id  :integer          indexed
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  archive     :binary
#  status      :integer
#  name        :string           indexed
#  metadata    :string           default({})
#  deleted_at  :datetime         indexed
#
# Indexes
#
#  index_release_orders_on_deleted_at  (deleted_at)
#  index_release_orders_on_name        (name)
#  index_release_orders_on_release_id  (release_id)
#

class ReleaseOrder < ActiveRecord::Base
  acts_as_paranoid

  include Putit::ActiveRecordLogging
  include Wisper.model

  serialize :metadata, JSON

  belongs_to :release

  has_many :approvals, dependent: :destroy
  has_many :release_order_application_with_versions, dependent: :destroy
  has_many :application_with_versions,
           through: :release_order_application_with_versions
  has_many :release_order_results
  has_many :release_order_envs

  validates_uniqueness_of :name
  validates_presence_of :name
  validates_format_of :name, with: /\A[\w\. -]+\z/

  scope :upcoming, -> { where('release_orders.end_date >= ? and release_orders.status IN (?)', Date.today, [ReleaseOrder.statuses[:working], ReleaseOrder.statuses[:waiting_for_approvals], ReleaseOrder.statuses[:approved]]) }

  enum status: %i[working waiting_for_approvals approved in_deployment deployed failed unknown closed]

  after_create :set_default_status

  def serializable_hash(options = {})
    included_relations = []
    included_relations += options[:include] if options && options[:include]

    result = super({
      only: %i[id name start_date end_date description status],
      include: included_relations
    })

    result[:applications_with_versions] = release_order_application_with_versions
    result[:approvers] = approvals.map(&:user).map(&:email)
    result[:release] = release

    result
  end

  def send_approval_emails
    approvals.each do |a|
      ApprovalMailer.deliver_approval_email(a)
    end
  end

  def valid_date?
    (start_date..end_date) === Time.now
  end

  def valid_approvals?
    approvals.all?(&:accepted)
  end

  def validate_status(status)
    enums = ReleaseOrder.statuses.map(&:first)
    unless enums.include? status
      raise PutitExceptions::EnumError, "Invalid status: #{status}, valids are: \"#{enums}\""
    end
  end

  private

  def set_default_status
    working!
    true
  end
end
