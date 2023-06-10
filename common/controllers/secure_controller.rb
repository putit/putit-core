class SecureController < PutitController
  before do
    check_token
  end

  private

  def check_token
    authorization = request.env['HTTP_AUTHORIZATION']
    unless authorization
      halt 401, { status: 'error', errors: 'Auth required' }.to_json
    end
    type, token = authorization.split(' ')
    unless type == 'Bearer'
      halt 401, { status: 'error', errors: 'Missing Bearer token type.' }.to_json
    end
    unless token
      halt 401, { status: 'error', errors: 'Missing Bearer token type.' }.to_json
    end
    if token_blocked(token)
      halt 401, { status: 'error', errors: 'Token was invalidated.' }.to_json
    end
    unless token_decode(token)
      halt 401, { status: 'error', errors: 'Unable to decode token.' }.to_json
    end
  end

  def token_blocked(encoded_token)
    BlockedToken.exists?(token: encoded_token)
  end

  def token_decode(encoded_token)
    options, payload = encoded_token.split('.')
    options = JSON.parse(Base64.decode64(options), symbolize_names: true)
    payload = JSON.parse(Base64.decode64(payload), symbolize_names: true)

    if payload[:user_type] == 'api'
      user = ApiUser.find_by_email(payload[:user])
    elsif payload[:user_type] == 'web'
      user = User.find_by_email(payload[:user])
    end

    JWT.decode encoded_token, user.secret_key, true, algorithm: options[:alg]
    RequestStore.store[:current_user] ||= user.email
    RequestStore.store[:cu] ||= user
    logger.info("User \"#{user.email}\" authorized.", user_type: payload[:user_type])
    true
  rescue StandardError
    false
  end
end
