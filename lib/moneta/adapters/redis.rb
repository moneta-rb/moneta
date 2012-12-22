require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis < Base
      # Constructor
      #
      # @param [Hash] options
      #
      # Options:
      # * :expires - Default expiration time (default none)
      # * Other options passed to Redis#new
      def initialize(options = {})
        @expires = options.delete(:expires)
        @redis = ::Redis.new(options)
      end

      def key?(key, options = {})
        if @redis.exists(key)
          if expires = options[:expires]
            @redis.expire(key, expires)
          end
          true
        else
          false
        end
      end

      def load(key, options = {})
        value = @redis.get(key)
        if value && (expires = options[:expires])
          @redis.expire(key, expires)
        end
        value
      end

      def store(key, value, options = {})
        if expires = (options[:expires] || @expires)
          @redis.setex(key, expires, value)
        else
          @redis.set(key, value)
        end
        value
      end

      def delete(key, options = {})
        if value = load(key, options)
          @redis.del(key)
          value
        end
      end

      def increment(key, amount = 1, options = {})
        value = @redis.incrby(key, amount)
        expires = (options[:expires] || @expires)
        @redis.expire(key, expires) if expires
        value
      end

      def clear(options = {})
        @redis.flushdb
        self
      end
    end
  end
end
