# == Schema Information
#
# Table name: release_order_results
#
#  id                          :integer          not null, primary key
#  release_order_id            :integer          indexed, indexed => [env_id, application_id]
#  env_id                      :integer          indexed, indexed => [release_order_id, application_id]
#  status                      :integer          default("unknown")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  application_id              :integer          indexed => [release_order_id, env_id]
#  application_with_version_id :integer
#  log                         :text             default("")
#
# Indexes
#
#  index_release_order_results_on_env_id            (env_id)
#  index_release_order_results_on_release_order_id  (release_order_id)
#  uniq_result                                      (release_order_id,env_id,application_id) UNIQUE
#

describe ReleaseOrderResult, type: :model do
  it { is_expected.to define_enum_for(:status)
                      .with_values(%i[unknown success failure]) }
  it { is_expected.to belong_to(:release_order) }
  it { is_expected.to belong_to(:env) }
  it { is_expected.to belong_to(:application) }
  it { is_expected.to belong_to(:application_with_version) }
end
