require 'net/http'

module Moneta
  module Adapters
    # Moneta rest client backend which works together with {Rack::MonetaRest}
    # @api public
    class RestClient
      include Defaults

      attr_reader :backend

      # @param [Hash] options
      # @option options [String] :url URL
      # @option options [::Net::HTTP] :backend Use existing backend instance
      def initialize(options = {})
        raise ArgumentError, 'Option :url is required' unless url = options[:url]
        url = URI(url)
        @path = url.path
        @backend = options[:backend] || ::Net::HTTP.start(url.host, url.port)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        response = @backend.request_head(@path + key)
        response.code == '200'
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = @backend.request_get(@path + key)
        response.code == '200' ? response.body : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        response = @backend.request_post(@path + key, value)
        raise "HTTP error #{response.code}" unless response.code == '200'
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        response = @backend.request(::Net::HTTP::Delete.new(@path + key))
        response.code == '200' ? response.body : nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        @backend.request(::Net::HTTP::Delete.new(@path))
        self
      end

      # (see Proxy#close)
      def close
        @backend.finish
        nil
      end
    end
  end
end
