require 'sshkey'
class ManageSSHKeyService
  def self.generate_key(type, bits, comment, _passphrase)
    k = SSHKey.generate(
      type: type,
      bits: bits.to_i,
      comment: comment
    )
    k
  end
end
