begin
  require "memcached"
  MemCache = Memcached
rescue LoadError
  begin
    require "memcache"
  rescue LoadError
    puts "You need either the `memcached` or `memcache-client` gem to use the Memcache moneta store"
  end
end

module Moneta
  module Adapters
    class Memcache
      include Moneta::Defaults

      def initialize(options = {})
        @cache = ::MemCache.new(options.delete(:server), options)
      end

      def key?(key, *)
        !self[key].nil?
      end

      def [](key)
        deserialize(@cache.get(key_for(key)))
      rescue MemCache::NotFound
      end

      def delete(key, *)
        value = self[key]
        @cache.delete(key_for(key)) if value
        value
      end

      def store(key, value, *)
        @cache.set(key_for(key), serialize(value))
      end

      def clear(*)
        @cache.flush
      end

    private
      def key_for(key)
        [super].pack("m").strip
      end
    end
  end
end
