# == Schema Information
#
# Table name: host_credentials
#
#  id            :integer          not null, primary key
#  host_id       :integer          indexed
#  credential_id :integer          indexed
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_host_credentials_on_credential_id  (credential_id)
#  index_host_credentials_on_host_id        (host_id)
#

class HostCredential < ActiveRecord::Base
  belongs_to :host
  belongs_to :credential
end
