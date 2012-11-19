require 'redis'

module Juno
  class Redis < Base
    def initialize(options = {})
      @store = ::Redis.new(options)
    end

    def key?(key, options = {})
      @store.exists(key_for(key))
    end

    def fetch(key, value = nil, options = {})
      result = super
      if result && expires = options[:expires]
        @store.expire(key_for(key), expires)
      end
      result
    end

    def [](key)
      deserialize(@store.get(key_for(key)))
    end

    def delete(key, options = {})
      string_key = key_for(key)
      value = self[key]
      @store.del(string_key) if value
      value
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
