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

class Credential < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :depuser
  belongs_to :sshkey, class_name: 'DepSSHKey'

  validates_presence_of :name
  validates_uniqueness_of :name

  def serializable_hash(_options = {})
    { id: id,
      name: name,
      sshkey_name: sshkey.name,
      depuser_name: depuser.username }
  end

  def get_env_private_key_filename(env, application)
    group_name = "#{env.name}-#{application.dir_name}"
    "#{group_name}_#{name}.key"
  end

  def get_env_public_key_filename(env, application)
    group_name = "#{env.name}-#{application.dir_name}"
    "#{group_name}.pub"
  end

  def get_host_private_key_filename(env, host, application)
    "#{host.fqdn}-#{env.name}-#{application.dir_name}_#{name}.key"
  end

  def get_host_public_key_filename(env, host, application)
    "#{host.fqdn}-#{env.name}-#{application.dir_name}.pub"
  end
end
