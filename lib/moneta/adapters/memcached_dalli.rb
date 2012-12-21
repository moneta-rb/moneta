require 'dalli'

module Moneta
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

      def load(key, options = {})
        value = @cache.get(key)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      end

      def store(key, value, options = {})
        @cache.set(key, value, options[:expires], :raw => true)
        value
      end

      def delete(key, options = {})
        value = @cache.get(key)
        @cache.delete(key)
        value
      end

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
          puts 'Warning: Counter created in a non thread-safe manner'
          store(key, amount, options)
          amount
        end
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
