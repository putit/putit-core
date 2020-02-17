# == Schema Information
#
# Table name: release_order_application_with_version_envs
#
#  id                                        :integer          not null, primary key
#  release_order_application_with_version_id :integer          indexed
#  env_id                                    :integer          indexed
#  created_at                                :datetime         not null
#  updated_at                                :datetime         not null
#
# Indexes
#
#  env_ro_avw  (release_order_application_with_version_id)
#  env_ro_env  (env_id)
#

class ReleaseOrderApplicationWithVersionEnv < ActiveRecord::Base
  belongs_to :release_order_application_with_version
  belongs_to :env
end
