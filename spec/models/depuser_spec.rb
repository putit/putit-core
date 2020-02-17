# == Schema Information
#
# Table name: depusers
#
#  id         :integer          not null, primary key
#  username   :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime         indexed
#
# Indexes
#
#  index_depusers_on_deleted_at  (deleted_at)
#

describe Depuser, type: :model do
  describe 'username' do
    it { is_expected.to validate_presence_of(:username) }
    it { is_expected.to allow_value('_user1234$').for(:username) }
    it { is_expected.to allow_value('app_user_1').for(:username) }
    it { is_expected.not_to allow_value(' _user1234$').for(:username) }
  end
end
