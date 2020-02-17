describe DepuserController do
  it 'should return all depusers' do
    get '/depuser'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result.length).to eq 3
  end

  it 'should return depuser by name' do
    get '/depuser/app_user_3'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:username]).to eq 'app_user_3'
  end

  it 'should delete depuser by name' do
    id = Depuser.find_by_username('app_user_3').id

    delete '/depuser/app_user_3'

    expect(last_response.status).to eq 202

    result = JSON.parse(last_response.body, symbolize_names: true)

    expect(result[:status]).to eq 'ok'
    expect(Depuser.exists?(id)).to eq false
  end

  it 'should create new depuser' do
    payload = {
      username: 'new_user'
    }

    post '/depuser', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(Depuser.all.length).to eq 4
    expect(Depuser.last.username).to eq 'new_user'
  end

  it 'should return user if exists when creating' do
    payload = {
      username: 'app_user_3'
    }

    post '/depuser', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(Depuser.all.length).to eq 3
    expect(Depuser.last.username).to eq 'app_user_3'
  end

  describe 'credentials' do
    it 'should return credential assigned to depuser' do
      get '/depuser/app_user_3/sshkeys'

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[0][:name]).to eq 'credential3'
      expect(result[0][:sshkey_name]).to eq 'sshkey3'
      expect(result[0][:depuser_name]).to eq 'app_user_3'
    end

    it 'should create new credentials for depuser' do
      d = Depuser.create!(username: 'test-depuser')
      k = DepSSHKey.first

      payload = {
        key_name: k.name,
        name: 'new credential'
      }

      post '/depuser/test-depuser/sshkeys', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      c = Credential.find_by_name('new credential')

      expect(c.sshkey_id).to eq k.id
      expect(c.depuser_id).to eq d.id
    end

    it 'should not create duplicate credentials' do
      d = Depuser.create!(username: 'test-depuser')
      k = DepSSHKey.first
      c = Credential.create!(
        name: 'existing credential',
        sshkey_id: k.id,
        depuser_id: d.id
      )

      payload = {
        key_name: k.name,
        name: 'existing credential'
      }

      post '/depuser/test-depuser/sshkeys', payload.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 409
    end

    it 'should delete credential from depuser' do
      d = Depuser.create!(username: 'test-depuser')
      k = DepSSHKey.first

      payload = {
        key_name: k.name,
        name: 'new credential'
      }

      post '/depuser/test-depuser/sshkeys', payload.to_json, 'CONTENT_TYPE': 'application/json'

      delete "/depuser/test-depuser/sshkeys/#{k.name}"

      expect(last_response.status).to eq 202

      expect(Credential.exists?(name: 'new credential')).to eq false
    end
  end
end
