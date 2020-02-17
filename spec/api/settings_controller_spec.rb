describe SettingsController do
  it 'should return settings' do
    DBSetting.create(key: 'key1', value: 'true')

    get '/settings'

    expect(last_response).to be_ok

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:putit_core_url]).to eq 'localhost:9292'
    expect(result[:putit_auth_url]).to eq 'localhost:3000'
    expect(result[:key1]).to eq 'true'
  end

  it 'should return setting by key' do
    DBSetting.create(key: 'key1', value: 'true')

    get '/settings/key1'

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:key1]).to eq 'true'
  end

  it 'should return 404 when key does not exists' do
    get '/settings/not%20exists'

    expect(last_response.status).to eq 404
  end

  it 'set new db setting' do
    payload = {
      key: 'key1',
      value: 'true'
    }

    post '/settings', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 200

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DBSetting.first.key).to eq 'key1'
  end

  it 'set new db settings from Array' do
    payload = [{
      key: 'key1',
      value: 'value1'
    }, {
      key: 'key2',
      value: 'value2'
    }]

    post '/settings', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 200

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DBSetting.first.key).to eq 'key1'
    expect(DBSetting.second.key).to eq 'key2'
  end

  it 'update value for key' do
    DBSetting.create(key: 'key1', value: 'value1')
    DBSetting.create(key: 'key2', value: 'value2')

    payload = [{
      key: 'key1',
      value: 'new value1'
    }, {
      key: 'key2',
      value: 'new value2'
    }]

    post '/settings', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 200

    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:status]).to eq 'ok'

    expect(DBSetting.first.value).to eq 'new value1'
    expect(DBSetting.second.value).to eq 'new value2'
  end

  it 'should not change the type of value' do
    payload = {
      key: 'key1',
      value: true
    }

    post '/settings', payload.to_json, 'CONTENT_TYPE': 'application/json'

    expect(last_response.status).to eq 200

    get '/settings/key1'

    expect(last_response.status).to eq 200
    result = JSON.parse(last_response.body, symbolize_names: true)
    expect(result[:key1]).to eq true
  end
end
