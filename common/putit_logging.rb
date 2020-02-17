module PutitLogging
  class AppLogger
    def initialize(logger, event_source)
      @_logger = logger
      @_event_source = event_source
    end

    def debug(message, log_event = {})
      _log(:debug, message, log_event)
    end

    def info(message, log_event = {})
      _log(:info, message, log_event)
    end

    def warn(message, log_event = {})
      _log(:warn, message, log_event)
    end

    def error(message, log_event = {})
      _log(:error, message, log_event)
    end

    def fatal(message, log_event = {})
      _log(:fatal, message, log_event)
    end

    def flush
      @_logger.appenders[0].flush
    end

    def puts(message)
      error(message)
    end

    private

    def _log(level, message, log_event)
      event_source = @_event_source.class.name
      if RequestStore.read(:current_user)
        current_user = RequestStore.read(:current_user)
      elsif @_event_source.respond_to?(:current_user) && !@_event_source.current_user.nil?
        current_user = @_event_source.current_user
      else
        current_user ||= '-'
      end

      if RequestStore.read(:request_id)
        request_id = RequestStore.read(:request_id)
      elsif @_event_source.respond_to?(:request_id) && !@_event_source.request_id.nil?
        request_id = @_event_source.request_id
      end

      if @_event_source.respond_to?(:env) && @_logger.level == 0
        request = @_event_source.request
        log_event['controller'] = request.path.to_s[%r{^/[a-z]+}].delete('/').upcase
        log_event['request_path'] = request.path
        log_event['request_method'] = request.request_method
      end

      logger_message = nil

      if @_logger.appenders[0].layout == JSON_LAYOUT
        log_event['msg'] = message.to_s
        log_event['user'] = @_event_source.current_user

        logger_message = log_event
      else
        log_items = log_event.keys.map do |key|
          "#{key} => #{log_event[key]}"
        end

        logger_message_main = [
          "[#{current_user}]", "[#{request_id}]", "[#{event_source}]", message.to_s
        ].join(' ')

        if log_items.any?
          extra_data = [
            ' Extra data:', log_items.join('; ')
          ].join(' ')
          logger_message = logger_message_main.concat(extra_data)
        else
          logger_message = logger_message_main
        end
      end

      @_logger.add(Logging.level_num(level), logger_message)
    end
  end
end
