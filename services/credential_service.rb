class CredentialService < PutitService
  def add_dep_ssh_key(payload)
    logger.info('Generating new SSH keys')

    k = ManageSSHKeyService.generate_key(
      payload[:type],
      payload[:bits],
      payload[:comment],
      payload[:passphrase]
    )

    ssh_key = DepSSHKey.find_or_create_by!(
      name: payload[:name],
      keytype: k.type,
      bits: k.bits,
      comment: k.comment,
      private_key: k.private_key,
      public_key: k.public_key,
      ssh_public_key: k.ssh_public_key,
      ssh2_public_key: k.ssh2_public_key,
      sha256_fingerprint: k.sha256_fingerprint
    )

    logger.info(
      "New SSH key pair has been generated with name: #{payload[:name]}"
    )

    ssh_key
  end

  def add_depuser(payload)
    depuser = Depuser.find_or_create_by!(username: payload[:username])
    logger.info("Deploy user: #{payload[:username]} created.")

    depuser
  end

  def add_depuser_credential(depuser, credential_name, ssh_key)
    credential = depuser.credentials.create!(
      sshkey_id: ssh_key.id,
      depuser_id: depuser.id,
      name: credential_name
    )

    logger.info("Credential with name: #{credential_name} for SSH key pair with name: #{ssh_key[:name]} and deploy username: #{depuser.username} created.")

    credential
  end
end
