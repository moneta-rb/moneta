require 'redis'

module Juno
  class Redis < Base
    def initialize(options = {})
      @store = ::Redis.new(options)
    end

    def key?(key, options = {})
      @store.exists(key_for(key))
    end

    def load(key, options = {})
      value = deserialize(@store.get(key_for(key)))
      if value && (expires = options[:expires])
        @store.expire(key_for(key), expires)
      end
      value
    end

    def delete(key, options = {})
      if value = load(key, options)
        @store.del(key_for(key))
        value
      end
    end

    def store(key, value, options = {})
      key = key_for(key)
      @store.set(key, serialize(value))
      if expires = options[:expires]
        @store.expire(key, expires)
      end
      value
    end

    def clear(options = {})
      @store.flushdb
      nil
    end
  end
end
