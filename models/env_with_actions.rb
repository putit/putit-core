# == Schema Information
#
# Table name: env_action_events
#
#  id            :integer          not null, primary key
#  env_action_id :integer          indexed
#  event_id      :integer          indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
# TODO
#

class EnvWithAction < ActiveRecord::Base
  belongs_to :env_action
  belongs_to :env
end
