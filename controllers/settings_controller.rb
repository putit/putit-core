class SettingsController < SecureController
  get '/' do
    settings = DBSetting.all.reduce({}) { |h, setting| h.merge(Hash[setting.key, setting.value]) }
    settings['putit_core_url'] = Settings.putit_core_url
    settings['putit_auth_url'] = Settings.putit_auth_url
    settings.to_json
  end

  get '/:key' do |key|
    setting = DBSetting.find_by_key(key)

    if setting.nil?
      request_halt("Setting with key \"#{key}\" does not exists.", 404)
    end

    Hash[setting.key, setting.value].to_json
  end

  post '/' do
    result = JSON.parse(request.body.read, symbolize_names: true)

    Array.wrap(result).each do |setting|
      DBSetting.find_or_create_by(key: setting[:key]).update_attribute('value', setting[:value])
    end

    { status: 'ok' }.to_json
  end
end
