require 'dalli'

module Juno
  module Adapters
    # Memcached backend (using gem dalli)
    # @api public
    class MemcachedDalli < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :server - Memcached server (default localhost:11211)
      # * Other options passed to Dalli::Client#new
      def initialize(options = {})
        server = options.delete(:server) || 'localhost:11211'
        @cache = ::Dalli::Client.new(server, options)
      end

      def key?(key, options = {})
        !!@cache.get(key)
      end

      def load(key, options = {})
        value = @cache.get(key)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      end

      def store(key, value, options = {})
        @cache.set(key, value, options[:expires])
        value
      end

      def delete(key, options = {})
        value = @cache.get(key)
        @cache.delete(key)
        value
      end

      def clear(options = {})
        @cache.flush_all
        self
      end

      def close
        @cache.close
        nil
      end
    end
  end
end
