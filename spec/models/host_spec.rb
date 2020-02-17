# == Schema Information
#
# Table name: hosts
#
#  id         :integer          not null, primary key
#  fqdn       :string           not null, indexed => [env_id]
#  name       :string
#  ip         :string
#  env_id     :integer          indexed, indexed => [fqdn]
#  deleted_at :datetime         indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_hosts_on_deleted_at       (deleted_at)
#  index_hosts_on_env_id           (env_id)
#  index_hosts_on_fqdn_and_env_id  (fqdn,env_id) UNIQUE
#

describe Host, type: :model do
  describe 'name' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to allow_value('ProperHost_name-123.45').for(:name) }
    it { is_expected.not_to allow_value('{}[] ').for(:name) }
  end

  describe 'ip' do
    it { is_expected.to validate_presence_of(:ip) }
    it { is_expected.to allow_value('192.168.2.1').for(:ip) }
    it { is_expected.not_to allow_value('not an IP address').for(:ip) }
  end

  describe 'fqdn' do
    it { is_expected.to validate_presence_of(:fqdn) }
    it { is_expected.to allow_value('server1.com').for(:fqdn) }
    it { is_expected.not_to allow_value('not a valid fqdn').for(:fqdn) }
  end

  it { is_expected.to have_one(:credential).through(:host_credential) }
end
