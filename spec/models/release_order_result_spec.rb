# == Schema Information
#
# Table name: release_order_results
#
#  id                          :integer          not null, primary key
#  release_order_id            :integer
#  env_id                      :integer
#  status                      :integer          default("unknown")
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  application_id              :integer
#  application_with_version_id :integer
#  log                         :text             default("")
#

describe ReleaseOrderResult, type: :model do
  it { is_expected.to define_enum_for(:status)
                      .with_values(%i[unknown success failure]) }
  it { is_expected.to belong_to(:release_order) }
  it { is_expected.to belong_to(:env) }
  it { is_expected.to belong_to(:application) }
  it { is_expected.to belong_to(:application_with_version) }
end
