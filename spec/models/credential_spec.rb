# == Schema Information
#
# Table name: credentials
#
#  id         :integer          not null, primary key
#  sshkey_id  :integer          indexed
#  depuser_id :integer          indexed
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  comment    :string
#  deleted_at :datetime         indexed
#  name       :string           indexed
#
# Indexes
#
#  index_credentials_on_deleted_at  (deleted_at)
#  index_credentials_on_depuser_id  (depuser_id)
#  index_credentials_on_name        (name)
#  index_credentials_on_sshkey_id   (sshkey_id)
#

describe Credential, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_uniqueness_of(:name) }
end
