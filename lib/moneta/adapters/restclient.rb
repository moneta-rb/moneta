require 'httpi'

module Moneta
  module Adapters
    # Moneta rest client backend which works together with `Rack::MonetaRest`
    # @api public
    class RestClient
      include Defaults

      # @param [Hash] options
      # @option options [String] :url URL
      def initialize(options = {})
        raise ArgumentError, 'Option :url is required' unless @url = options[:url]
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        response = HTTPI.head(@url + key)
        response.code == 200
      end

      # (see Proxy#load)
      def load(key, options = {})
        response = HTTPI.get(@url + key)
        response.code == 200 ? response.body : nil
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        raise "HTTP #{response.code}" if HTTPI.post(@url + key, value).error?
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        response = HTTPI.delete(@url + key)
        response.code == 200 ? response.body : nil
      end

      # (see Proxy#clear)
      def clear(options = {})
        HTTPI.delete(@url)
        self
      end
    end
  end
end
