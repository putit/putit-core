# == Schema Information
#
# Table name: env_actions
#
#  id            :integer          not null, primary key
#  env_action_id :integer          indexed
#  uuid          :string(36)       indexed
#  data          :string
#  status        :integer          default("enabled")
#  name          :string
#  description   :string
#  deleted_at    :datetime         indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_env_actions_on_deleted_at     (deleted_at)
#  index_env_actions_on_env_action_id  (env_action_id)
#  index_env_actions_on_uuid           (uuid)
#

describe EnvAction, type: :model do
  it { is_expected.to validate_presence_of(:name) }
end
