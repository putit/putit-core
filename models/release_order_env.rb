# == Schema Information
#
# Table name: release_order_envs
#
#  id               :integer          not null, primary key
#  release_order_id :integer
#  env_id           :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_release_order_envs_on_env_id            (env_id)
#  index_release_order_envs_on_release_order_id  (release_order_id)
#

class ReleaseOrderEnv < ActiveRecord::Base
  belongs_to :release_order
  belongs_to :env
end
