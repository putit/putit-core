require 'sinatra'

module Putit
  module Integration
    class IntegrationBase
      class << self
        attr_reader :endpoint
      end

      def self.on_webhook(&handler)
        @handler = handler
      end

      def self.listen_for_webhook_on_url(endpoint)
        @endpoint = endpoint
      end

      def self.handler(data)
        @handler.call(data)
      end

      def self.call(env)
        status, response = @handler.call(env['rack.input'].read, Rack::Request.new(env))
        [status, { 'Content-Type' => 'application/json' }, [response]]
      end
    end
  end
end
