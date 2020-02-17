# == Schema Information
#
# Table name: approvals
#
#  id               :integer          not null, primary key
#  name             :string
#  uuid             :string(36)       indexed
#  email            :string
#  accepted         :boolean          default(FALSE)
#  release_order_id :integer          indexed, indexed => [user_id]
#  user_id          :integer          indexed, indexed => [release_order_id]
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sent             :boolean          default(FALSE)
#  deleted_at       :datetime         indexed
#
# Indexes
#
#  index_approvals_on_deleted_at                    (deleted_at)
#  index_approvals_on_release_order_id              (release_order_id)
#  index_approvals_on_user_id                       (user_id)
#  index_approvals_on_user_id_and_release_order_id  (user_id,release_order_id) UNIQUE
#  index_approvals_on_uuid                          (uuid)
#

class Approval < ActiveRecord::Base
  include ActiveModel::Dirty

  acts_as_paranoid

  before_create :generate_uuid
  after_save :approve_release_order, if: :saved_change_to_accepted?

  belongs_to :release_order
  belongs_to :user

  private

  def generate_uuid
    self.uuid = UUIDTools::UUID.random_create
    true
  end

  def approve_release_order
    release_order.approved! if release_order.valid_approvals?
  end
end
