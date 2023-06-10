# == Schema Information
#
# Table name: env_actions
#
#  id            :integer          not null, primary key
#  env_action_id :integer
#  uuid          :string(36)
#  data          :string
#  status        :integer          default("enabled")
#  name          :string
#  description   :string
#  deleted_at    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  enabled       :boolean          default(TRUE)
#

describe EnvAction, type: :model do
  it { is_expected.to validate_presence_of(:name) }
end
