describe SSHKeyController do
  it 'should add new SSH key' do
    properties = {
      name: 'sshkey4',
      type: 'DSA',
      bits: 1024,
      comment: 'Created via API',
      passphrase: 'password'
    }

    post '/sshkey', properties.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 201

    result = JSON.parse(last_response.body, symbolize_names: true)

    ssh_key = DepSSHKey.find_by_name('sshkey4')

    expect(ssh_key.bits).to eq 1024
    expect(ssh_key.keytype).to eq 'dsa'
    expect(ssh_key.comment).to eq 'Created via API'
  end

  it 'should get key\'s fingerprint by name' do
    get '/sshkey/sshkey1/fingerprint'

    expect(last_response).to be_ok
    expect(last_response.body).to eq DepSSHKey.find_by_name('sshkey1').sha256_fingerprint
  end

  it 'should get key\'s public key by name' do
    get '/sshkey/sshkey1/ssh_public_key'

    expect(last_response).to be_ok
    expect(last_response.body).to eq DepSSHKey.find_by_name('sshkey1').ssh_public_key
  end

  it 'should get key\'s public key 2 by name' do
    get '/sshkey/sshkey1/ssh2_public_key'

    expect(last_response).to be_ok
    expect(last_response.body).to eq DepSSHKey.find_by_name('sshkey1').ssh2_public_key
  end

  it 'should return error when ssh key does not exists' do
    get '/sshkey/666/ssh_public_key'

    expect(last_response.status).to eq 404

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:msg]).to eq 'SSH key with name "666" does not exists.'
  end

  it 'should delete SSH key' do
    name = DepSSHKey.first.name

    delete "/sshkey/#{name}"

    expect(last_response.status).to eq 202

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DepSSHKey.exists?(name: name)).to eq false
  end
end
