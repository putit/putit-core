class SSHKeyController < SecureController

  before '/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @key = DepSSHKey.find_by_name(name)

    if @key.nil?
      request_halt("SSH key with name \"#{name}\" does not exists.", 404)
    end
  end

  post '/' do
    status 201

    json = JSON.parse(request.body.read, symbolize_names: true)
    ssh_key = CredentialService.new.add_dep_ssh_key(json)

    { id: ssh_key.id }.to_json
  end

  get '/' do
    DepSSHKey.all.map { |k| k.slice(:id, :name, :comment, :sha256_fingerprint, :keytype, :bits) }.to_json
  end

  delete '/:name' do
    status 202

    @key.destroy
    logger.info("Deleted SSH key pair with name: #{@key.name}")

    { status: 'ok' }.to_json
  end

  get '/:name/fingerprint' do
    @key.sha256_fingerprint
  end

  get '/:name/ssh_public_key' do
    @key.ssh_public_key
  end

  get '/:name/ssh2_public_key' do
    @key.ssh2_public_key
  end

  # make it only internal
  # get '/:name/ssh_private_key' do
  #  @key.private_key
  # end
end
