class EnvActionController < SecureController

  get '/' do
    EnvAction.all.to_json
  end

  post '/' do
    status 201

    json = JSON.parse(request.body.read)

    env_action = EnvAction.create!(json)
    logger.info("Created env_action with name: #{json['name']}")

    env_action.to_json
  end
end
