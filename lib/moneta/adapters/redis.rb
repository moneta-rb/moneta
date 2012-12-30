require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis
      include Defaults
      include ExpiresSupport

      # @param [Hash] options
      # @option options [Integer] :expires Default expiration time
      # @option options Other options passed to `Redis#new`
      def initialize(options = {})
        self.default_expires = options.delete(:expires)
        @redis = ::Redis.new(options)
      end

      # (see Proxy#key?)
      def key?(key, options = {})
        if @redis.exists(key)
          update_expires(key, options, nil)
          true
        else
          false
        end
      end

      # (see Proxy#load)
      def load(key, options = {})
        value = @redis.get(key)
        update_expires(key, options, nil)
        value
      end

      # (see Proxy#store)
      def store(key, value, options = {})
        if expires = expires_value(options)
          @redis.setex(key, expires, value)
        else
          @redis.set(key, value)
        end
        value
      end

      # (see Proxy#delete)
      def delete(key, options = {})
        if value = load(key, options)
          @redis.del(key)
          value
        end
      end

      # (see Proxy#increment)
      def increment(key, amount = 1, options = {})
        value = @redis.incrby(key, amount)
        update_expires(key, options)
        value
      end

      # (see Proxy#clear)
      def clear(options = {})
        @redis.flushdb
        self
      end

      protected

      def update_expires(key, options, default = @default_expires)
        case expires = expires_value(options, default)
        when false
          @redis.persist(key)
        when Numeric
          @redis.expire(key, expires)
        end
      end
    end
  end
end
