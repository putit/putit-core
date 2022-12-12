require 'sshkey'
class ManageSSHKeyService
  def self.generate_key(type, bits, comment, _passphrase)
    SSHKey.generate(
      type: type,
      bits: bits.to_i,
      comment: comment
    )
  end
end
