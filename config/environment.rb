require 'set'
require 'open-uri'
require 'net/http'
require 'net/https'
require 'active_support'
require 'active_support/concern'
require 'active_support/all'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/reloader'
require 'sinatra/streaming'
require 'sinatra/multi_route'
require 'sinatra/config_file'
require 'sinatra/param'
require 'paper_trail'
require 'paper_trail/config'
require 'validates_hostname'
require 'active_model'
require 'rack/parser'
require 'i18n'
require 'i18n/backend/fallbacks'
require 'json'
require 'yaml'
require 'active_record/immutable'
require 'paranoia'
require 'amoeba'
require 'base64'
require 'jwt'
require 'thin'
require 'resolv'
require 'wisper'
require 'wisper/activerecord'
require 'uuidtools'
require 'pony'
require 'logging'
require 'config'
require 'moneta'
require 'acts_as_list'
require 'open3'
require 'semantic'
require 'semantic/core_ext'
require './helpers/request_handler'
require './common/putit_logging'
require './common/putit_exceptions'
require 'jsonb_accessor'

Thin::Logging.debug = true

Config.load_and_set_settings(File.join(File.dirname(__FILE__), 'settings.yml'))

# Logging
PLAIN_LAYOUT = Logging.layouts.pattern(
  pattern: '[%d] %-5l %c: %m\n',
  date_pattern: '%Y-%m-%d %H:%M:%S:%s'
)

JSON_LAYOUT = Logging.layouts.json(items: %w[timestamp level message])

DEFAULT_LOGGER_SETTINGS = {
  output: :stdout,
  level: :debug,
  age: 'daily',
  layout: :plain
}

def configure_logger(name_)
  logger_settings = DEFAULT_LOGGER_SETTINGS

  name = Settings.logging && Settings.logging[name_]
  if name
    logger_settings = {
      output: name.output || DEFAULT_LOGGER_SETTINGS[:output],
      level: name.level || DEFAULT_LOGGER_SETTINGS[:level],
      age: name.age || DEFAULT_LOGGER_SETTINGS[:age],
      layout: name.layout || DEFAULT_LOGGER_SETTINGS[:layout]
    }
    logger_settings['layout'] = 'plain' if name == 'deployment'
  end

  if ENV['RACK_ENV'] == 'test'
    logger_settings[:output] = 'stringio'
    logger_settings[:layout] = 'plain'
  end

  logger = Logging.logger[name_.upcase]
  logger.level = logger_settings[:level]

  layout = PLAIN_LAYOUT
  layout = JSON_LAYOUT if logger_settings[:layout].to_sym == :json

  if logger_settings[:output].to_sym == :stdout
    logger.add_appenders(Logging.appenders.stdout(layout: layout))
  elsif logger_settings[:output].to_sym == :stringio
    logger.add_appenders(Logging.appenders.string_io(layout: layout))
  else
    logger.add_appenders(Logging.appenders.rolling_file(
                           logger_settings[:output],
                           age: logger_settings[:age],
                           layout: layout
                         ))
  end

  logger
end

ACCESS_LOGGER = configure_logger('access')
APP_LOGGER = configure_logger('app')
BUSINESS_LOGGER = configure_logger('business')
ERROR_LOGGER = configure_logger('error')
JIRA_LOGGER = configure_logger('jira')
DEPLOY_LOGGER = configure_logger('deployment')
SERVICE_LOGGER = configure_logger('service')

SQL_LOGGER = configure_logger('sql')
ActiveRecord::Base.logger = SQL_LOGGER

configure :development do
  register Sinatra::Reloader
end

configure do
  I18n::Backend::Simple.include I18n::Backend::Fallbacks
  I18n.backend.load_translations
end

set :environment, :development

ANSIBLE_TABLES = %w[files templates handlers tasks vars defaults]

# rubocop:disable Metrics/LineLength
FQDN_REGEX = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-_]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
# rubocop:enable Metrics/LineLength

PROPERTIES_STORE = begin
  Moneta.build do
    use(:Pool) do
      adapter :Memory
    end
  end
end

# properties values for those keys will be anonymized by XXXX in logs
DEFAULT_ANONYMIZE_PROPERTIES = %w[password passphrase]
ANONYMIZE_PROPERTIES = Settings.anonymize_properties || DEFAULT_ANONYMIZE_PROPERTIES

require './common/controllers/putit_controller'
require './common/controllers/secure_controller'
require './common/services/putit_service'
require './plugins/integrations/integration_base'
Dir['./common/*.rb'].each { |file| require file }
Dir['./models/ansible/*.rb'].each { |file| require file }
Dir['./models/paper_trail/*.rb'].each { |file| require file }
Dir['./models/*.rb'].each { |file| require file }
Dir['./services/make_playbook/*.rb'].each { |file| require file }
Dir['./services/env_actions/*.rb'].each { |file| require file }
Dir['./services/*.rb'].each { |file| require file }
Dir['./controllers/**/*.rb'].each { |file| require file }
Dir['./mailers/*.rb'].each { |file| require file }
Dir['./helpers/*.rb'].each { |file| require file }
Dir['./models/wisper/*observer.rb'].each { |file| require file }
Dir['./models/wisper/global_listener.rb'].each { |file| require file }
Dir['./plugins/integrations/**/initialize.rb'].each { |file| require file }
Dir['./plugins/integrations/**/models/*.rb'].each { |file| require file }

# Dir["#{Settings.plugins_path}/**/service.rb"].each do |file|
#  require file
# end

use Rack::Parser
use RequestStore::Middleware
