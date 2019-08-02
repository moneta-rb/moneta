require 'faraday'

module Moneta
  module Adapters
    # Moneta rest client backend which works together with {Rack::MonetaRest}
    # @api public
    class RestClient
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :url URL
      # @option options [Symbol] :adapter The adapter to tell Faraday to use
      # @option options [Faraday::Connection] :backend Use existing backend instance
      # @option options Other options passed to {Faraday::new} (unless
      #   :backend option is provided).
      def initialize(options = {})
        @backend = options.delete(:backend) ||
          begin
            raise ArgumentError, 'Option :url is required' unless url = options.delete(:url)
            block = if faraday_adapter = options.delete(:adapter)
                      proc { |faraday| faraday.adapter faraday_adapter }
                    end
            ::Faraday.new(url, options, &block)
          end
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        @backend.head(key).status == 200
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.get(key)
        response.status == 200 ? response.body : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        response = @backend.post(key, value)
        raise "HTTP error #{response.status}" unless response.status == 200
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        response = @backend.delete(key)
        response.status == 200 ? response.body : nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.delete ''
        self
      end
    end
  end
end
