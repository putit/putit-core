# == Schema Information
#
# Table name: credentials
#
#  id         :integer          not null, primary key
#  sshkey_id  :integer
#  depuser_id :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  comment    :string
#  deleted_at :datetime
#  name       :string
#

describe Credential, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
end
