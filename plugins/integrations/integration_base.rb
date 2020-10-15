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
        req = Rack::Request.new(env)
        [200, { 'Content-Type' => 'text/plain' }, [@handler.call(env['rack.input'].read)] ]
      end
    end
  end
end
