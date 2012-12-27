require 'dalli'

module Moneta
  module Adapters
    # Memcached backend (using gem dalli)
    # @api public
    class MemcachedDalli
      include Defaults

      # @param [Hash] options
      # @option options [String] :server ('127.0.0.1:11211') Memcached server
      # @option options [Integer] :expires Default expiration time
      # @option options Other options passed to `Dalli::Client#new`
      def initialize(options = {})
        options[:expires_in] = options.delete(:expires)
        server = options.delete(:server) || '127.0.0.1:11211'
        @cache = ::Dalli::Client.new(server, options)
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @cache.get(key)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        @cache.set(key, value, options[:expires], :raw => true)
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        value = @cache.get(key)
        @cache.delete(key)
        value
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        # FIXME: There is a Dalli bug, load(key) returns a wrong value after increment
        # therefore we set default = nil and create the counter manually
        result = if amount >= 0
                   @cache.incr(key, amount, options[:expires], nil)
                 else
                   @cache.decr(key, -amount, options[:expires], nil)
                 end
        if result
          result
        else
          store(key, amount, options)
          amount
        end
      end

      # (see Proxy#clear)
      def clear(options = {})
        @cache.flush_all
        self
      end

      # (see Proxy#close)
      def close
        @cache.close
        nil
      end
    end
  end
end
