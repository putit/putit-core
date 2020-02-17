describe CredentialController do
  it 'should return all Credentials' do
    get '/credential'

    expect(last_response).to be_ok
    result = JSON.parse(last_response.body, symbolize_names: true)

    expect(result.length).to eq 3
  end

  it 'should delete Credential by name' do
    name = Credential.first.name

    delete "/credential/#{name}"

    expect(last_response).to be_ok
    result = JSON.parse(last_response.body, symbolize_names: true)

    expect(result[:status]).to eq 'ok'

    expect(Credential.exists?(name: name)).to eq false
  end
end
