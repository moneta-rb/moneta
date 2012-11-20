require 'memcached'

module Juno
  module Adapters
    class MemcachedNative < Base
      def initialize(options = {})
        server = options.delete(:server) || 'localhost:11211'
        options.merge!(:prefix_key => options.delete(:namespace)) if options[:namespace]
        @cache = ::Memcached.new(server, options)
      end

      def key?(key, options = {})
        @cache.get(key, false)
        true
      rescue ::Memcached::NotFound
        false
      end

      def load(key, options = {})
        value = @cache.get(key, false)
        if value && options.include?(:expires)
          store(key, value, options)
        else
          value
        end
      rescue ::Memcached::NotFound
      end

      def delete(key, options = {})
        value = @cache.get(key, false)
        @cache.delete(key)
        value
      rescue ::Memcached::NotFound
      end

      def store(key, value, options = {})
        @cache.set(key, value, options[:expires] || @cache.options[:default_ttl], false)
        value
      end

      def clear(options = {})
        @cache.flush
        self
      end
    end
  end
end
