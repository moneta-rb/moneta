require 'redis'

module Juno
  module Adapters
    class Redis < Base
      def initialize(options = {})
        @redis = ::Redis.new(options)
      end

      def key?(key, options = {})
        @redis.exists(key)
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
        @redis.set(key, value)
        if expires = options[:expires]
          @redis.expire(key, expires)
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
