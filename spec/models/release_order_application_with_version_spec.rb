# == Schema Information
#
# Table name: release_order_application_with_versions
#
#  id                          :integer          not null, primary key
#  release_order_id            :integer
#  application_with_version_id :integer
#

describe ReleaseOrderApplicationWithVersion, type: :model do
  it { is_expected.to have_many(:release_order_application_with_version_envs) }
  it { is_expected.to have_many(:envs).through(:release_order_application_with_version_envs) }
end
