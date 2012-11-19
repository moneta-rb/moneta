require 'dalli'

module Juno
  class MemcachedDalli < Base
    def initialize(options = {})
      server = options.delete(:server) || 'localhost:11211'
      @cache = ::Dalli::Client.new(server, options)
    end

    def key?(key, options = {})
      !!@cache.get(key_for(key))
    end

    def load(key, options = {})
      value = deserialize(@cache.get(key_for(key)))
      if value && options.include?(:expires)
        store(key, value, options)
      else
        value
      end
    end

    def store(key, value, options = {})
      @cache.set(key_for(key), serialize(value), options[:expires])
      value
    end

    def delete(key, options = {})
      key = key_for(key)
      value = deserialize(@cache.get(key))
      @cache.delete(key)
      value
    end

    def clear(options = {})
      @cache.flush_all
      nil
    end

    def close
      @cache.close
      nil
    end

    private

    def key_for(key)
      [super].pack('m').strip
    end
  end
end
