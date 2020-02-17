# == Schema Information
#
# Table name: env_credentials
#
#  id            :integer          not null, primary key
#  env_id        :integer          indexed
#  credential_id :integer          indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_env_credentials_on_credential_id  (credential_id)
#  index_env_credentials_on_env_id         (env_id)
#

class EnvCredential < ActiveRecord::Base
  belongs_to :env
  belongs_to :credential
end
