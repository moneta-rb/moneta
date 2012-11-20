module Juno
  class Cache < Base
    attr_reader :backend, :cache

    def initialize(store, cache)
      @backend, @cache = store, cache
    end

    def key?(key, options = {})
      @cache.key?(key, options) || @backend.key?(key, options)
    end

    def load(key, options = {})
      value = @cache.load(key, options)
      unless value
        value = @backend.load(key, options)
        @cache.store(key, value, options) if value
      end
      value
    end

    def store(key, value, options = {})
      @cache.store(key, value, options)
      @backend.store(key, value, options)
    end

    def delete(key, options = {})
      @cache.delete(key, options)
      @backend.delete(key, options)
    end

    def clear(options = {})
      @cache.clear(options)
      @backend.clear(options)
    end

    def close
      @cache.close
      @backend.close
    end
  end
end
