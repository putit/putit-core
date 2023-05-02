source 'https://rubygems.org'

gem 'actionmailer'
gem 'activerecord'
gem 'activerecord-immutable'
gem 'activesupport'
gem 'activeuuid'
gem 'acts_as_list'
gem 'amoeba'
gem 'config'
gem 'i18n'
gem 'jsonb_accessor'
gem 'jwt'
gem 'log4r'
gem 'logging'
gem 'psych'
gem 'moneta'
gem 'paper_trail'
gem 'paper_trail-sinatra'
gem 'paranoia', '~> 2.2'
gem 'pg'
gem 'pony'
gem 'rack'
gem 'rack-parser', require: 'rack/parser'
gem 'rake'
gem 'request_store'
gem 'rubyzip'
gem 'semantic'
gem 'sinatra'
gem 'sinatra-activerecord'
gem 'sinatra-contrib'
gem 'sinatra-param'
gem 'openssl'
gem 'sshkey'
gem 'thin'
gem 'validates_hostname', '~> 1.0'
gem 'wisper-activerecord'

group :test do
  gem 'database_cleaner'
  gem 'memfs'
  gem 'rack-test', require: 'rack/test'
  gem 'rspec'
  gem 'rspec-mocks'
  gem 'shoulda-matchers'
  gem 'sqlite3'
  gem 'vcr'
  gem 'webmock'
end

group :development do
  gem 'annotate'
  gem 'pry'
  gem 'rails-erd'
  gem 'rubocop', require: false
end

require 'yaml'
settings_file = File.join(__dir__, 'config/settings.yml')
if File.file?(settings_file)
  settings = YAML.load_file(settings_file)
  Dir["#{settings['plugins_path']}/**/Gemfile"].each do |file|
    instance_eval(File.read(file))
  end
end
