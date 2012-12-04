require 'memcached'

module Juno
  module Adapters
    # Memcached backend (using gem memcached)
    # @api public
    class MemcachedNative < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :server - Memcached server (default localhost:11211)
      # * :namespace - Key namespace
      # * Other options passed to Memcached#new
      def initialize(options = {})
        server = options.delete(:server) || 'localhost:11211'
        options.merge!(:prefix_key => options.delete(:namespace)) if options[:namespace]
        @default_ttl = options[:default_ttl] || 604800
        @cache = ::Memcached.new(server, options)
      end

      def key?(key, options = {})
        @cache.get(key, false)
        true
      rescue ::Memcached::NotFound
        false
      end

      def load(key, options = {})
        value = @cache.get(key, false)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      rescue ::Memcached::NotFound
      end

      def delete(key, options = {})
        value = @cache.get(key, false)
        @cache.delete(key)
        value
      rescue ::Memcached::NotFound
      end

      def store(key, value, options = {})
        # TTL must be Fixnum
        @cache.set(key, value, options[:expires] || @default_ttl, false)
        value
      end

      def clear(options = {})
        @cache.flush
        self
      end
    end
  end
end
