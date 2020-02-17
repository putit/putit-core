# == Schema Information
#
# Table name: release_orders
#
#  id          :integer          not null, primary key
#  start_date  :datetime
#  end_date    :datetime
#  description :text
#  release_id  :integer          indexed
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  archive     :binary
#  status      :integer
#  name        :string           indexed
#  metadata    :string           default({})
#  deleted_at  :datetime         indexed
#
# Indexes
#
#  index_release_orders_on_deleted_at  (deleted_at)
#  index_release_orders_on_name        (name)
#  index_release_orders_on_release_id  (release_id)
#

describe ReleaseOrder, type: :model do
  let(:r) { Release.first }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
  it { is_expected.to have_many(:release_order_results) }
  it {
    is_expected.to define_enum_for(:status)
      .with_values(%i[working waiting_for_approvals approved in_deployment deployed failed unknown closed])
  }
  it { is_expected.to allow_value('Prop_name-1.45 have space').for(:name) }
  it { is_expected.not_to allow_value(' ').for(:name) }
  it { is_expected.not_to allow_value('/').for(:name) }

  it 'should set default state as "working"' do
    r = ReleaseOrder.create(name: 'temp release')

    expect(r.status).to eq 'working'
  end

  describe 'Deleting' do
    it 'should delete approvals as well' do
      r = ReleaseOrder.create!(name: 'temp release') do |ro|
        ro.approvals.build
      end

      id = r.id
      approval_id = r.approvals.first.id

      r.destroy

      expect(ReleaseOrder.exists?(id)).to eq false
      expect(Approval.exists?(approval_id)).to eq false
    end
  end

  describe 'Valid dates' do
    it 'should be active only between given dates' do
      now = Time.now

      release_order = r.release_orders.create!(name: '1', start_date: now - 2.days, end_date: now + 2.days)
      expect(release_order.valid_date?).to eq true
    end

    it 'should not be active when outside date ranges' do
      now = Time.now

      release_order = r.release_orders.create!(name: '2', start_date: now - 6.days, end_date: now - 2.days)
      expect(release_order.valid_date?).to eq false
    end
  end

  describe 'Valid approvals' do
    it 'should be active when all approvals are accepted' do
      release_order = ReleaseOrder.first

      app_1 = release_order.approvals.create(name: 'Approval 1')
      app_2 = release_order.approvals.create(name: 'Approval 2')

      expect(release_order.valid_approvals?).to eq false

      app_1.update(accepted: true)

      expect(release_order.valid_approvals?).to eq false

      app_2.update(accepted: true)

      expect(release_order.valid_approvals?).to eq true
    end
  end
end
