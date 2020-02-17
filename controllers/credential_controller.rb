class CredentialController < SecureController

  before '/*' do |name|
    pass if params['splat'][0].blank?
    name = params['splat'][0].split('/')[0]
    @credential = Credential.find_by_name(name)
    if @credential.nil?
      request_halt("Credential \"#{name}\" does not exists.", 404)
    end
  end

  get '/' do
    Credential.all.to_json
  end

  delete '/:name' do |_name|
    @credential.destroy

    { status: 'ok' }.to_json
  end

  get '/:name/ssh_public_key' do |_name|
    @credential.sshkey.ssh_public_key
  end
end
