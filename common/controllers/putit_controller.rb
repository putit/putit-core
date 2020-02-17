class PutitController < Sinatra::Base
  # helpers Sinatra::CustomLogger
  helpers RequestHandler
  helpers Sinatra::Param

  configure :production, :development, :test do
    set :show_exceptions, false
    # test it
    # set :raise_errors, false
    #
    # set :logger, PutitLogging::AppLogger.new(APP_LOGGER, self)
  end

  configure :production, :test do
    use Rack::CommonLogger, ACCESS_LOGGER
  end

  before do
    request_uuid = UUIDTools::UUID.random_create.to_s
    RequestStore.store[:request_id] ||= request_uuid

    env['rack.errors'] = PutitLogging::AppLogger.new(ERROR_LOGGER, self)
    env['rack.logger'] = PutitLogging::AppLogger.new(APP_LOGGER, self)

    logger.debug 'Request started.'
  end

  after do
    logger.debug('Request ended.', 'http_code' => status)
    @halted = true if RequestStore.read(:halted)
    RequestStore.clear!
  end

  error ActiveRecord::RecordInvalid, ActiveRecord::UnknownAttributeError, JSON::ParserError, Sinatra::Param::InvalidParameterError, ActiveRecord::RecordNotUnique do
    ex = env['sinatra.error']
    duplication_regex = /Validation failed.*has already been taken$/
    json_unexpected_token_regex = /.*unexpected token at.*/
    if duplication_regex.match(ex.message)
      request_halt(ex.message, 409)
    elsif ex.class.to_s == 'ActiveRecord::RecordNotUnique'
      request_halt(ex.message, 409)
    elsif json_unexpected_token_regex.match(ex.message)
      msg = 'JSON parsing error.'
      request_halt(msg, 400)
    else
      request_halt(ex.message, 400)
    end
  end

  error ActiveRecord::RecordNotFound do
    ex = env['sinatra.error']
    request_halt(ex.message, 404)
  end

  # custom putit errors which should end up with 409
  error PutitExceptions::DuplicateDeploymentResult do
    ex = env['sinatra.error']
    request_halt(ex.message, 409)
  end

  # custom putit errors which should end up with 400
  error PutitExceptions::EnumError, PutitExceptions::HostDNSError, PutitExceptions::MakePlaybookServiceError, PutitExceptions::SemanticTermError, PutitExceptions::SemanticNotValidVersion do
    ex = env['sinatra.error']
    request_halt(ex.message, 400)
  end

  not_found do
    { status: 'error', msg: 'Resource cannot be found' }.to_json unless @halted
  end
end
