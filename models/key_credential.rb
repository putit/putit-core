class KeyCredentials < ActiveRecord::Base
  belongs_to :host

  def serializable_hash(_options = {})
    { ssh_prv_key: ssh_prv_key,
      ssh_pub_key: ssh_pub_key,
      ssh_username: ssh_username }
  end
end
