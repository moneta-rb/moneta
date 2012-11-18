require 'memcached'

module Juno
  class MemcachedNative < Base
    def initialize(options = {})
      server = options.delete(:server) || 'localhost:11211'
      @cache = ::Memcached.new(server, options)
    end

    def key?(key, options = {})
      @cache.get(key_for(key), false)
      true
    rescue ::Memcached::NotFound
      false
    end

    def fetch(key, value = nil, options = {})
      result = super
      if result && options.include?(:expires)
        store(key, result, options)
      else
        result
      end
    end

    def [](key)
      deserialize(@cache.get(key_for(key), false))
    rescue ::Memcached::NotFound
    end

    def delete(key, options = {})
      key = key_for(key)
      value = deserialize(@cache.get(key, false))
      @cache.delete(key)
      value
    rescue ::Memcached::NotFound
    end

    def store(key, value, options = {})
      ttl = options[:expires] || ::Memcached::DEFAULTS[:default_ttl]
      @cache.set(key_for(key), serialize(value), ttl, false)
      value
    end

    def clear(options = {})
      @cache.flush
      nil
    end

    private

    def key_for(key)
      [super].pack('m').strip
    end
  end
end
