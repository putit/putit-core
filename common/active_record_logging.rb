module Putit
  module ActiveRecordLogging
    extend ActiveSupport::Concern

    included do
      after_create lambda { |model|
        model_name = model.class.name
        logger = PutitLogging::AppLogger.new(APP_LOGGER, self)

        attr_to_log = attributes

        # do not log belows
        %w[password private_key passphrase encrypted_private_key].each do |str|
          attr_to_log[str] = 'XXXXXXXXXX' if has_attribute?(str)
        end
        logger.info(
          "#{model_name} has been created with parameters: #{attr_to_log}"
        )
      }
    end
  end
end
