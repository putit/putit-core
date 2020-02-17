describe ArtifactController do
  describe 'Adding artifacts' do
    it 'should add new artifacts from JSON' do
      artifacts = [{
        name: 'a1-html',
        version: '1.0.0'
      }]

      post '/artifact', artifacts.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 1

      expect(Artifact.all.length).to eq 3

      artifact = Artifact.find_by_name('a1-html')
    end

    it 'should append version to existing artifact' do
      artifact = [{
        name: 'a1-html',
        version: '1.0.0'
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      artifact = [{
        name: 'a1-html',
        version: '2.0.0'
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 1

      expect(Artifact.all.length).to eq 3
    end

    it 'should return 400 when creating Release with wrong payload' do
      artifact = [{
        name: '',
        version: ''
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 400
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq "Validation failed: Name can't be blank, Name is invalid"
    end
  end

  describe 'Getting artifacts' do
    it 'Should return Artifact with Versions' do
      get '/artifact/index'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:versions].length).to eq 3
    end

    it 'Should return only versions' do
      get '/artifact/index/versions'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result.length).to eq 3
      expect(result[0][:version]).to eq '1.0.0'
      expect(result[1][:version]).to eq '2.0.0'
      expect(result[2][:version]).to eq '3.0.0'
    end

    it 'Should return Artifact with specific version' do
      get '/artifact/index/version/1.0.0'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:id]).to eq 1
      expect(result[:version_id]).to eq 1
    end

    it 'Should return 404 when Artifact does not exists' do
      get '/artifact/not%20exists'

      expect(last_response.status).to eq 404
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:msg]).to eq 'Artifact with name "not exists" does not exists.'
    end

    it 'Should return 404 when Version does not exists' do
      get '/artifact/index/version/1.0.0'

      expect(last_response).to be_ok

      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:id]).to eq 1
      expect(result[:version_id]).to eq 1
    end
  end

  describe 'Artifact properties' do
    it 'should add properties for given Id and Version' do
      a = Artifact.find_by_name('index')
      v = a.versions.find_by_version('2.0.0')

      properties = {
        'install_path' => '/install',
        'mode' => '0666'
      }
      post '/artifact/index/version/2.0.0/properties', properties.to_json

      expect(last_response.status).to eq 202
      result = JSON.parse(last_response.body, symbolize_names: true)
      expect(result[:status]).to eq 'ok'

      avw = ArtifactWithVersion.find_by_artifact_id_and_version_id(a.id, v.id)
      expect(PROPERTIES_STORE[avw.properties_key]).to eq properties
    end

    it 'should return properties for given Id and Version' do
      get '/artifact/other/version/1.4.1/properties'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      expect(result['install_dir']).to eq '/tmp'
      expect(result['source_path']).to eq '/opt/source/other/html/1.4.1/other.html'
      expect(result['mode']).to eq '0666'
    end

    it 'should clone properties from last artifact version' do
      artifact = [{
        name: 'other',
        version: '2.0.0'
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      get '/artifact/other/version/2.0.0/properties'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      expect(result['install_dir']).to eq '/tmp'
      expect(result['source_path']).to eq '/opt/source/other/html/1.4.1/other.html'
      expect(result['mode']).to eq '0666'
    end

    it 'should set default properties when there are no previous properties' do
      artifact = [{
        name: 'new',
        version: '1.0.0'
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      artifact = [{
        name: 'new',
        version: '2.0.0'
      }]

      post '/artifact', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      get '/artifact/new/version/2.0.0/properties'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      expect(result['artifact_name']).to eq 'new'
      expect(result['artifact_version']).to eq '2.0.0'
    end

    it 'should not clone properties when there\'s dontCloneProperties param' do
      artifact = [{
        name: 'other',
        version: '2.0.0'
      }]

      post '/artifact?dontCloneProperties=true', artifact.to_json, 'CONTENT_TYPE': 'application/json'

      expect(last_response.status).to eq 201

      get '/artifact/other/version/2.0.0/properties'

      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)

      expect(result['artifact_name']).to eq 'other'
      expect(result['artifact_version']).to eq '2.0.0'
    end
  end

  it 'should delete artifact' do
    a = Artifact.first
    id = a.id

    delete '/artifact/index'

    expect(last_response.status).to eq 202
    expect(Artifact.exists?(id)).to eq false
  end
end
