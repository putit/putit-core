# == Schema Information
#
# Table name: env_actions
#
#  id            :integer          not null, primary key
#  env_action_id :integer          indexed
#  uuid          :string(36)       indexed
#  data          :string
#  status        :integer          default("enabled")
#  name          :string
#  description   :string
#  deleted_at    :datetime         indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_env_actions_on_deleted_at     (deleted_at)
#  index_env_actions_on_env_action_id  (env_action_id)
#  index_env_actions_on_uuid           (uuid)
#

class EnvAction < ActiveRecord::Base
  serialize :data

  acts_as_paranoid

  validates_presence_of :name

  enum status: %i[enabled disabled]

  has_many :env_with_actions
  has_many :envs, through: :env_with_actions

  before_create :generate_uuid

  def serializable_hash(_options = {})
    { id: id,
      name: name,
      status: status,
      description: description,
      enabled: enabled,
      uuid: uuid,
      data: data }
  end

  private

  def generate_uuid
    self.uuid = UUIDTools::UUID.random_create
    true
  end
end
