class DepuserController < SecureController

  before '/*' do
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @depuser = Depuser.find_by_username(name)

    if @depuser.nil?
      request_halt("Deploy user with name '#{name}' does not exists.", 404)
    end
  end

  get '/' do
    content_type :json

    Depuser.all.to_json
  end

  get '/:username' do |_username|
    @depuser.to_json
  end

  delete '/:username' do |_username|
    status 202
    @depuser.destroy

    { status: 'ok' }.to_json
  end

  post '/' do
    status 201

    json = JSON.parse(request.body.read, symbolize_names: true)

    depuser = CredentialService.new.add_depuser(json)
    depuser.to_json
  end

  get '/:username/sshkeys' do |_username|
    @depuser.credentials.to_json
  end

  post '/:username/sshkeys' do |_username|
    status 201

    json = JSON.parse(request.body.read, symbolize_names: true)
    name = json[:name]
    sshkey = DepSSHKey.find_by_name(json[:key_name])
    if sshkey.nil?
      request_halt("Unable to create credential with name '#{name}' as SSH keys with name #{json[:key_name]} does not exists.", 404)
    end

    credential = CredentialService.new.add_depuser_credential(
      @depuser, json[:name], sshkey
    )

    credential.to_json
  end

  delete '/:username/sshkeys/:key_name' do |_username, key_name|
    status 202

    sshkey = DepSSHKey.find_by_name(key_name)
    if sshkey.nil?
      request_halt("Unable to delete SSH keys pair name '#{key_name}' as such pair does not exists.", 404)
    end
    credential = @depuser.credentials.find_by_sshkey_id(sshkey.id)

    credential&.destroy
  end
end
