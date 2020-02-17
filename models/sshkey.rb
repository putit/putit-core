class DepSSHKey < ActiveRecord::Base
  acts_as_paranoid

  validates_presence_of :name
  validates_uniqueness_of :name

  self.table_name = 'sshkeys'

  has_many :credentials, foreign_key: 'sshkey_id', dependent: :destroy
  has_many :depusers, through: :credentials

  def serializable_hash(_options = {})
    { id: id,
      name: name,
      keytype: keytype,
      bits: bits,
      comment: comment,
      passphrase: passphrase,
      private_key: private_key,
      encrypted_private_key: encrypted_private_key,
      public_key: public_key,
      ssh_public_key: ssh_public_key,
      ssh2_public_key: ssh2_public_key,
      sha256_fingerprint: sha256_fingerprint }
  end
end
