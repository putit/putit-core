# == Schema Information
#
# Table name: events
#
#  id         :integer          not null, primary key
#  env_id     :integer          indexed
#  source     :string
#  status     :integer
#  severity   :integer
#  uuid       :string(36)       indexed
#  data       :string
#  event_type :integer          default("operational")
#  deleted_at :datetime         indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_events_on_deleted_at  (deleted_at)
#  index_events_on_env_id      (env_id)
#  index_events_on_uuid        (uuid)
#

class Event < ActiveRecord::Base
  attr_accessor :run_actions

  serialize :data

  acts_as_paranoid

  include Wisper.model

  belongs_to :env

  validates_presence_of :source
  validates_format_of :source, with: /\A[\w\.-]+\Z/

  validates_presence_of :event_type
  enum event_type: %i[operational performance tests devel]

  enum status: %i[open closed acked]
  enum severity: %i[low moderate major critical]

  before_create :generate_uuid

  def run_actions
    Array.wrap(@run_actions) if @run_actions
  end

  def readonly?
    !new_record?
  end

  private

  def generate_uuid
    self.uuid = UUIDTools::UUID.random_create
    true
  end
end
