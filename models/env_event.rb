# == Schema Information
#
# Table name: env_events
#
#  id         :integer          not null, primary key
#  env_id     :integer
#  event_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class EnvEvent < ActiveRecord::Base
  belongs_to :env
  belongs_to :event
end
