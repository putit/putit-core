# == Schema Information
#
# Table name: envs
#
#  id             :integer          not null, primary key
#  name           :string           not null, indexed => [application_id]
#  application_id :integer          indexed, indexed => [name]
#  deleted_at     :datetime         indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  aws_tags       :string
#
# Indexes
#
#  index_envs_on_application_id           (application_id)
#  index_envs_on_deleted_at               (deleted_at)
#  index_envs_on_name_and_application_id  (name,application_id) UNIQUE
#

describe Env, type: :model do
  describe 'name' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to allow_value('roperEnv_name-123.45').for(:name) }
    it { is_expected.not_to allow_value('{}[]').for(:name) }
  end

  it { is_expected.to have_many(:release_order_results) }
  it { is_expected.to have_one(:credential).through(:env_credential) }

  it { is_expected.to have_many(:pipelines).class_name('DeploymentPipeline') }

  it { is_expected.to have_many(:events) }

  it 'should delete hosts as when env is deleted' do
    e = Application.first.envs.create!(name: 'to-delete')
    h1 = e.hosts.create!(fqdn: 'host1.putit.io', name: 'host1', ip: '127.0.0.1')
    h2 = e.hosts.create!(fqdn: 'host2.putit.io', name: 'host1', ip: '127.0.0.1')

    e.destroy

    expect(Host.exists?(h1.id)).to eq false
    expect(Host.exists?(h2.id)).to eq false
  end

  it 'should return proper properties_key' do
    a = Application.find_by_name('WEBv1')
    e = a.envs.find_by_name('dev')

    expect(e.properties_key).to eq '/application/WEBv1/envs/dev/properties'
  end

  it 'should properly keep ordering of pipelines' do
    e1 = Env.create(name: 'E1')
    e2 = Env.create(name: 'E2')

    p1 = DeploymentPipeline.create(name: 'P1')
    p2 = DeploymentPipeline.create(name: 'P2')

    clone1 = p1.amoeba_dup
    clone2 = p1.amoeba_dup
    clone3 = p2.amoeba_dup
    clone4 = p2.amoeba_dup

    e1.pipelines << clone1
    e1.pipelines << clone3

    expect(e1.pipelines.first.name).to eq 'P1'
    expect(e1.pipelines.last.name).to eq 'P2'

    e2.pipelines << clone2
    e2.pipelines << clone4

    expect(e2.pipelines.first.name).to eq 'P1'
    expect(e2.pipelines.last.name).to eq 'P2'

    e1.pipelines.last.move_higher

    expect(e1.pipelines.first.name).to eq 'P2'
    expect(e1.pipelines.last.name).to eq 'P1'

    e1.pipelines.last.move_lower

    expect(e1.pipelines.first).not_to be e2.pipelines.first
  end
end
