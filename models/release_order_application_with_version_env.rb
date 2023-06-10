# == Schema Information
#
# Table name: release_order_application_with_version_envs
#
#  id                                        :integer          not null, primary key
#  release_order_application_with_version_id :integer
#  env_id                                    :integer
#  created_at                                :datetime         not null
#  updated_at                                :datetime         not null
#

class ReleaseOrderApplicationWithVersionEnv < ActiveRecord::Base
  belongs_to :release_order_application_with_version
  belongs_to :env
end
