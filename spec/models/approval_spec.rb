# == Schema Information
#
# Table name: approvals
#
#  id               :integer          not null, primary key
#  name             :string
#  uuid             :string(36)
#  email            :string
#  accepted         :boolean          default(FALSE)
#  release_order_id :integer
#  user_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sent             :boolean          default(FALSE)
#  deleted_at       :datetime
#

describe Approval, type: :model do
  it { is_expected.to belong_to(:release_order) }
  it { is_expected.to belong_to(:user) }

  it 'should generate UUID before create' do
    a = Approval.create

    expect(a.uuid.length).to eq 36
  end
end
