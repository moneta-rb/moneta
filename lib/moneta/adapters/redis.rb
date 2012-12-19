require 'redis'

module Moneta
  module Adapters
    # Redis backend
    # @api public
    class Redis < Base
      # Constructor
      #
      # @param [Hash] options passed to Redis#new
      def initialize(options = {})
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

      def delete(key, options = {})
        if value = load(key, options)
          @redis.del(key)
          value
        end
      end

      def store(key, value, options = {})
        if expires = options[:expires]
          @redis.setex(key, expires, value)
        else
          @redis.set(key, value)
        end
        value
      end

      def clear(options = {})
        @redis.flushdb
        self
      end
    end
  end
end
