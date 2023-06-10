# == Schema Information
#
# Table name: host_credentials
#
#  id            :integer          not null, primary key
#  host_id       :integer
#  credential_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class HostCredential < ActiveRecord::Base
  belongs_to :host
  belongs_to :credential
end
