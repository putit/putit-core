# == Schema Information
#
# Table name: env_credentials
#
#  id            :integer          not null, primary key
#  env_id        :integer
#  credential_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class EnvCredential < ActiveRecord::Base
  belongs_to :env
  belongs_to :credential
end
