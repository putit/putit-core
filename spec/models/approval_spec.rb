# == Schema Information
#
# Table name: approvals
#
#  id               :integer          not null, primary key
#  name             :string
#  uuid             :string(36)       indexed
#  email            :string
#  accepted         :boolean          default(FALSE)
#  release_order_id :integer          indexed, indexed => [user_id]
#  user_id          :integer          indexed, indexed => [release_order_id]
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  sent             :boolean          default(FALSE)
#  deleted_at       :datetime         indexed
#
# Indexes
#
#  index_approvals_on_deleted_at                    (deleted_at)
#  index_approvals_on_release_order_id              (release_order_id)
#  index_approvals_on_user_id                       (user_id)
#  index_approvals_on_user_id_and_release_order_id  (user_id,release_order_id) UNIQUE
#  index_approvals_on_uuid                          (uuid)
#

describe Approval, type: :model do
  it { is_expected.to belong_to(:release_order) }
  it { is_expected.to belong_to(:user) }

  it 'should generate UUID before create' do
    a = Approval.create

    expect(a.uuid.length).to eq 36
  end
end
