require 'memcached'

module Moneta
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
      # * :expires - Default expiration time (default 604800)
      # * Other options passed to Memcached#new
      def initialize(options = {})
        server = options.delete(:server) || 'localhost:11211'
        @expires = options.delete(:expires) || 604800
        options.merge!(:prefix_key => options.delete(:namespace)) if options[:namespace]
        @cache = ::Memcached.new(server, options)
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

      def store(key, value, options = {})
        # TTL must be Fixnum
        @cache.set(key, value, options[:expires] || @expires, false)
        value
      end

      def delete(key, options = {})
        value = @cache.get(key, false)
        @cache.delete(key)
        value
      rescue ::Memcached::NotFound
      end

      def increment(key, amount = 1, options = {})
        result = if amount >= 0
          @cache.increment(key, amount)
        else
          @cache.decrement(key, -amount)
        end
        # HACK: Throw error if applied to invalid value
        if result == 0
          value = @cache.get(key, false) rescue nil
          raise 'Tried to increment non integer value' unless value.to_s == value.to_i.to_s
        end
        result
      rescue ::Memcached::NotFound => ex
        store(key, amount.to_s, options)
        amount
      end

      def clear(options = {})
        @cache.flush
        self
      end
    end
  end
end
