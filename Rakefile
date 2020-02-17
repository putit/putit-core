require './config/environment.rb'
require 'sinatra/activerecord/rake'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'fileutils'
require 'json'
require 'pp'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format documentation'
  t.verbose = true
end

desc 'run pry console'
task :pry, :environment do |_t, args|
  ENV['RACK_ENV'] = args[:environment] || 'development'

  p "Executing in #{ENV['RACK_ENV']} environment."
  exec 'bundle exec pry -I . -r ./config/environment.rb'
end

desc 'save playbook'
task :save_playbook, :application_name do |_t, args|
  app_name = args[:application_name]
  pp ReleaseOrder.all
end

task default: :spec
