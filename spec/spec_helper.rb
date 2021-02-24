require 'rack/test'
require 'rspec'
require 'pp'
require 'pry'
require 'memfs'
require 'database_cleaner'
require 'json'
require 'uri'
require 'webmock'
require 'webmock/rspec'
require 'vcr'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../config/environment.rb', __dir__

require 'shoulda-matchers'
require 'rspec/logging_helper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
end

# service classes
class AService
  @@called = false

  def initialize(_event)
    @@called = true
  end

  def self.called
    @@called
  end

  def self.called=(value)
    @@called = value
  end
end

class BService
  @@called = false

  def initialize(_event)
    @@called = true
  end

  def self.called
    @@called
  end

  def self.called=(value)
    @@called = value
  end
end

class CService
  @@called = false

  def initialize(_event)
    @@called = true
  end

  def self.called
    @@called
  end

  def self.called=(value)
    @@called = value
  end
end

module RSpecMixin
  include Rack::Test::Methods

  def app
    Rack::Builder.new do
      map '/artifact' do
        run ArtifactController
      end

      map '/application' do
        run ApplicationController
      end

      map '/release' do
        run ReleaseController
      end

      map '/step' do
        run StepController
      end

      map '/approve' do
        run ApprovalController
      end

      map '/sshkey' do
        run SSHKeyController
      end

      map '/status' do
        run StatusController
      end

      map '/depuser' do
        run DepuserController
      end

      map '/settings' do
        run SettingsController
      end

      map '/credential' do
        run CredentialController
      end

      map '/pipeline' do
        run PipelineController
      end

      map '/integration/jira' do
        run JiraController
      end

      map '/setup_wizard' do
        run SetupWizardController
      end

      map '/orders' do
        run OrderController
      end

      Putit::Integration::IntegrationBase.descendants.each do |plugin|
        map("/handlers/#{plugin.endpoint}") { run plugin }
      end

      map '/' do
        run ReleaseController
      end
    end
  end
end

ActiveRecord::Migration.maintain_test_schema!

Mail.defaults do
  delivery_method :test
end
Pony.override_options = { via: :test }

Config.load_and_set_settings(File.join(File.dirname(__FILE__), 'settings.yml'))

RSpec.configure do |config|
  config.include RSpecMixin
  config.include(Shoulda::Matchers::ActiveModel, type: :model)
  config.include(Shoulda::Matchers::ActiveRecord, type: :model)
  config.include RSpec::LoggingHelper

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.capture_log_messages(from: 'BUSINESS')

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    load File.expand_path '../db/seeds.rb', __dir__
  end

  config.before(:each) do
    DatabaseCleaner.strategy = :transaction

    allow_any_instance_of(SecureController).to receive(:check_token).and_return(true)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    AService.called = false
    BService.called = false
    CService.called = false

    PROPERTIES_STORE.clear
  end
end
