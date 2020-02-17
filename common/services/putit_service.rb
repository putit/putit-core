class PutitService
  attr_reader :logger, :request_id

  include PutitLogging

  def initialize(*_args, **keyword_args)
    @logger = PutitLogging::AppLogger.new(APP_LOGGER, self)
    if keyword_args[:request_id]
      @request_id = keyword_args[:request_id]
      @current_user = keyword_args[:current_user]
    end
  end

  def self.make_dir(path)
    FileUtils.mkdir_p path
  rescue StandardError => e
    raise PutitExceptions::MakePlaybookServiceError, "Unable to create dir: #{path} due to error: #{e.message}"
  end
end
