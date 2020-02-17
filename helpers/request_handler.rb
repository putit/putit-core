require 'sinatra/base'

module RequestHandler
  def request_halt(message, http_code)
    logger.error(message)
    RequestStore.store[:halted] = true
    halt http_code, { status: 'error', msg: message }.to_json
  end
end
