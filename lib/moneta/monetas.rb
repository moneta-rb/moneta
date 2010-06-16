module Moneta
  # A meta-store that is backed by one or more Moneta stores.
  # Read operations select a random store, write operations write to all stores.
  class Monetas
    def initialize(options = {})
      @caches = options[:stores] || raise("You must provide the :stores options")
    end

    module Implementation
      def key?(key)
        read_cache.key?(key)
      end

      def has_key?(key)
        key?(key)
      end

      def [](key)
        read_cache[key]
      end

      def fetch(key, value = nil)
        value ||= block_given? ? yield(key) : default # TODO: Shouldn't yield if key is present?
        read_cache[key] || value
      end

      def []=(key, value)
        @caches.map do |cache|
          cache[key] = value
        end.first
      end

      def delete(key)
        @caches.map do |cache|
          cache.delete(key)
        end.first
      end

      def store(*args)
        @caches.map do |cache|
          cache.store(*args)
        end.first
      end

      def clear(*args)
        @caches.map do |cache|
          cache.clear(*args)
        end.first
      end
    end

    # Unimplemented
    module Expiration
      def update_key(key, options)
      end
    end

    include Implementation
    include Expiration

    protected

      def read_cache
        @caches[rand(@caches.size)]
      end
  end
end
