class PutitVersioning < Semantic::Version
  attr_reader :logger, :request_id
  include PutitLogging

  def initialize(version)
    @logger = PutitLogging::AppLogger.new(APP_LOGGER, self)
    super
  end

  def set_version(term, options = {})
    log_msg = "Next version will be: #{term}."
    log_msg += " Prefix will be set to: #{options[:pre]}." if options.key?(:pre)
    if options.key?(:pre)
      log_msg += " Build will be set to: #{options[:build]}."
    end
    logger.info(log_msg)
    term = term.to_sym

    new_ver = public_send(term) if respond_to? term
    new_ver.pre = options[:pre] if options.key?(:pre) && new_ver
    new_ver.build = options[:build] if options.key?(:build) && new_ver
    logger.info("New version is set to: #{new_ver}")

    new_ver || false
  end

  def self.validate_term(term)
    valid_terms = %w[major minor patch]
    unless valid_terms.include? term
      raise PutitExceptions::SemanticTermError, "Invalid semantic version term: #{term}, valid ones are: #{valid_terms}"
    end
  end
end
